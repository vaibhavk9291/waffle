import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/bill.dart';
import '../domain/cart_item.dart';

class BillingRepository {
  final SupabaseService _supabase = SupabaseService.instance;
  static const _localBillsKey = 'local_saved_today_bills';

  Future<Map<String, dynamic>> createBill({
    required List<CartItem> items,
    required int discount,
    required String paymentMode,
  }) async {
    final payloadItems = items
        .map((i) => {
              'product_id': i.product.id,
              'qty': i.qty,
            })
        .toList();

    final subtotal = items.fold<int>(0, (sum, i) => sum + i.lineTotal);
    final total = (subtotal - discount).clamp(0, double.infinity).toInt();

    Map<String, dynamic> result;

    if (!_supabase.isInitialized) {
      await OfflineSyncService.instance.queueBill(
        items: payloadItems,
        discount: discount,
        paymentMode: paymentMode,
      );
      result = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'bill_no': await _getNextLocalBillNo(),
        'business_date': _supabase.currentISTDate,
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'payment_mode': paymentMode,
        'status': 'paid',
        'created_at': DateTime.now().toIso8601String(),
      };
    } else {
      try {
        final res = await _supabase.client.rpc('create_bill', params: {
          'items': payloadItems,
          'discount': discount,
          'payment_mode': paymentMode,
        });
        result = Map<String, dynamic>.from(res as Map);
      } catch (e) {
        debugPrint('createBill RPC error, queueing and storing locally: $e');
        await OfflineSyncService.instance.queueBill(
          items: payloadItems,
          discount: discount,
          paymentMode: paymentMode,
        );
        result = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'bill_no': await _getNextLocalBillNo(),
          'business_date': _supabase.currentISTDate,
          'subtotal': subtotal,
          'discount': discount,
          'total': total,
          'payment_mode': paymentMode,
          'status': 'paid',
          'created_at': DateTime.now().toIso8601String(),
        };
      }
    }

    // Always store in local today's bills cache for instant display
    await _saveBillLocally(result, items);
    return result;
  }

  Future<int> _getNextLocalBillNo() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('local_last_bill_no') ?? 0;
    final next = current + 1;
    await prefs.setInt('local_last_bill_no', next);
    return next;
  }

  Future<void> _saveBillLocally(Map<String, dynamic> billData, List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_localBillsKey) ?? [];
    final fullData = Map<String, dynamic>.from(billData);
    fullData['bill_items'] = items
        .map((i) => {
              'id': '',
              'bill_id': billData['id'],
              'product_id': i.product.id,
              'product_name': i.product.name,
              'unit_price': i.product.price,
              'qty': i.qty,
              'line_total': i.lineTotal,
            })
        .toList();
    list.insert(0, jsonEncode(fullData));
    await prefs.setStringList(_localBillsKey, list);
  }

  Future<List<Bill>> getTodayBills() async {
    final prefs = await SharedPreferences.getInstance();
    final localList = prefs.getStringList(_localBillsKey) ?? [];
    final today = _supabase.currentISTDate;

    final localBills = localList
        .map((s) {
          try {
            return Bill.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<Bill>()
        .where((b) => b.businessDate == today || b.businessDate.isEmpty)
        .toList();

    if (!_supabase.isInitialized) return localBills;

    try {
      final res = await _supabase.client
          .from('bills')
          .select('*, bill_items(*)')
          .eq('business_date', today)
          .order('created_at', ascending: false);

      final remoteBills = (res as List).map((e) => Bill.fromJson(e)).toList();

      // Merge and deduplicate by bill_no
      final map = <int, Bill>{};
      for (final b in localBills) {
        map[b.billNo] = b;
      }
      for (final b in remoteBills) {
        map[b.billNo] = b;
      }
      final merged = map.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return merged;
    } catch (e) {
      debugPrint('getTodayBills remote error, returning local: $e');
      return localBills;
    }
  }

  Future<bool> voidBill({required String billId, required String reason}) async {
    if (!_supabase.isInitialized) return false;
    try {
      final res = await _supabase.client.rpc('void_bill', params: {
        'p_bill_id': billId,
        'p_reason': reason,
      });
      return res as bool? ?? false;
    } catch (e) {
      debugPrint('voidBill error: $e');
      rethrow;
    }
  }

  /// Delete saved amounts and start completely fresh from scratch (atomic & fast)
  Future<void> clearSalesData({bool allDates = false}) async {
    // 1. Immediately wipe local cached data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localBillsKey);
    await prefs.remove('local_last_bill_no');
    await prefs.remove('offline_pending_bills');
    await prefs.remove('offline_pending_expenses');

    // 2. Immediately wipe Supabase database via atomic RPC
    if (_supabase.isInitialized) {
      try {
        await _supabase.client.rpc('reset_sales_data', params: {'p_all_dates': allDates});
      } catch (e) {
        debugPrint('reset_sales_data RPC fallback executing direct delete: $e');
        try {
          final today = _supabase.currentISTDate;
          if (allDates) {
            await _supabase.client.from('bill_items').delete().neq('product_name', '__dummy__');
            await _supabase.client.from('bills').delete().neq('status', '__dummy__');
            await _supabase.client.from('expenses').delete().neq('note', '__dummy__');
            await _supabase.client.from('daily_bill_counters').delete().neq('last_bill_no', -999);
          } else {
            final bills = await _supabase.client.from('bills').select('id').eq('business_date', today);
            for (final b in (bills as List)) {
              await _supabase.client.from('bill_items').delete().eq('bill_id', b['id']);
            }
            await _supabase.client.from('bills').delete().eq('business_date', today);
            await _supabase.client.from('expenses').delete().eq('business_date', today);
            await _supabase.client.from('daily_bill_counters').delete().eq('business_date', today);
          }
        } catch (innerError) {
          debugPrint('Direct delete notice: $innerError');
        }
      }
    }
  }
}
