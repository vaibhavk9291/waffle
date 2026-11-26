import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'supabase_service.dart';

class OfflineSyncService {
  static final OfflineSyncService instance = OfflineSyncService._internal();
  OfflineSyncService._internal();

  static const _pendingBillsKey = 'offline_pending_bills';
  static const _pendingExpensesKey = 'offline_pending_expenses';

  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  Future<void> init() async {
    await updatePendingCount();
  }

  Future<void> updatePendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final bills = prefs.getStringList(_pendingBillsKey) ?? [];
    final expenses = prefs.getStringList(_pendingExpensesKey) ?? [];
    pendingCount.value = bills.length + expenses.length;
  }

  Future<void> queueBill({
    required List<Map<String, dynamic>> items,
    required int discount,
    required String paymentMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bills = prefs.getStringList(_pendingBillsKey) ?? [];
    final txId = const Uuid().v4();
    final payload = {
      'tx_id': txId,
      'items': items,
      'discount': discount,
      'payment_mode': paymentMode,
      'queued_at': DateTime.now().toIso8601String(),
    };
    bills.add(jsonEncode(payload));
    await prefs.setStringList(_pendingBillsKey, bills);
    await updatePendingCount();
  }

  Future<void> queueExpense({
    required String note,
    required int amount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final expenses = prefs.getStringList(_pendingExpensesKey) ?? [];
    final txId = const Uuid().v4();
    final payload = {
      'tx_id': txId,
      'note': note,
      'amount': amount,
      'business_date': SupabaseService.instance.currentISTDate,
      'queued_at': DateTime.now().toIso8601String(),
    };
    expenses.add(jsonEncode(payload));
    await prefs.setStringList(_pendingExpensesKey, expenses);
    await updatePendingCount();
  }

  Future<void> syncAll() async {
    if (!SupabaseService.instance.isInitialized) return;
    final client = SupabaseService.instance.client;
    final prefs = await SharedPreferences.getInstance();

    // 1. Sync Bills
    final bills = prefs.getStringList(_pendingBillsKey) ?? [];
    final remainingBills = <String>[];
    for (final billStr in bills) {
      try {
        final data = jsonDecode(billStr) as Map<String, dynamic>;
        await client.rpc('create_bill', params: {
          'items': data['items'],
          'discount': data['discount'],
          'payment_mode': data['payment_mode'],
          'client_tx_id': data['tx_id'],
        });
      } catch (e) {
        debugPrint('Failed to sync bill, retaining in queue: $e');
        remainingBills.add(billStr);
      }
    }
    await prefs.setStringList(_pendingBillsKey, remainingBills);

    // 2. Sync Expenses
    final expenses = prefs.getStringList(_pendingExpensesKey) ?? [];
    final remainingExpenses = <String>[];
    for (final expStr in expenses) {
      try {
        final data = jsonDecode(expStr) as Map<String, dynamic>;
        await client.from('expenses').insert({
          'note': data['note'],
          'amount': data['amount'],
          'business_date': data['business_date'],
          'client_tx_id': data['tx_id'],
        });
      } catch (e) {
        debugPrint('Failed to sync expense, retaining in queue: $e');
        remainingExpenses.add(expStr);
      }
    }
    await prefs.setStringList(_pendingExpensesKey, remainingExpenses);
    await updatePendingCount();
  }
}
