import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';
import '../../billing/data/billing_repository.dart';
import '../../expenses/data/expense_repository.dart';
import '../domain/daily_total.dart';

class HistoryRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  Future<DailyTotal> getTodayTotal() async {
    final today = _supabase.currentISTDate;

    // Always fetch today's bills and expenses to ensure local and remote values match
    final bills = await BillingRepository().getTodayBills();
    final expenses = await ExpenseRepository().getTodayExpenses();

    final paidBills = bills.where((b) => !b.isVoid).toList();
    final localBillsCount = paidBills.length;
    final localItemsSold = paidBills.fold<int>(0, (sum, b) => sum + b.items.fold<int>(0, (iSum, i) => iSum + i.qty));
    final localGross = paidBills.fold<int>(0, (sum, b) => sum + b.total);
    final localDiscount = paidBills.fold<int>(0, (sum, b) => sum + b.discount);
    final localExpenses = expenses.where((e) => !e.isDeleted).fold<int>(0, (sum, e) => sum + e.amount);

    if (!_supabase.isInitialized) {
      return DailyTotal(
        businessDate: today,
        billsCount: localBillsCount,
        itemsSold: localItemsSold,
        grossRevenue: localGross,
        totalDiscount: localDiscount,
        expensesTotal: localExpenses,
        net: localGross - localExpenses,
      );
    }

    try {
      final res = await _supabase.client
          .from('daily_totals')
          .select()
          .eq('business_date', today)
          .maybeSingle();

      if (res != null) {
        final remote = DailyTotal.fromJson(res);
        // Take the higher of remote or local aggregated bills
        final maxGross = remote.grossRevenue > localGross ? remote.grossRevenue : localGross;
        final maxCount = remote.billsCount > localBillsCount ? remote.billsCount : localBillsCount;
        final maxItems = remote.itemsSold > localItemsSold ? remote.itemsSold : localItemsSold;
        final maxExpenses = remote.expensesTotal > localExpenses ? remote.expensesTotal : localExpenses;

        return DailyTotal(
          businessDate: today,
          billsCount: maxCount,
          itemsSold: maxItems,
          grossRevenue: maxGross,
          totalDiscount: remote.totalDiscount > localDiscount ? remote.totalDiscount : localDiscount,
          expensesTotal: maxExpenses,
          net: maxGross - maxExpenses,
        );
      }
    } catch (e) {
      debugPrint('getTodayTotal remote error, using aggregated local: $e');
    }

    return DailyTotal(
      businessDate: today,
      billsCount: localBillsCount,
      itemsSold: localItemsSold,
      grossRevenue: localGross,
      totalDiscount: localDiscount,
      expensesTotal: localExpenses,
      net: localGross - localExpenses,
    );
  }

  Future<List<DailyTotal>> getLast30DaysTotals() async {
    if (!_supabase.isInitialized) return [];
    try {
      final res = await _supabase.client
          .from('daily_totals')
          .select()
          .order('business_date', ascending: false)
          .limit(30);
      return (res as List).map((e) => DailyTotal.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getLast30DaysTotals error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDailyProductSummary(String date) async {
    if (!_supabase.isInitialized) return [];
    try {
      final res = await _supabase.client
          .from('daily_product_summary')
          .select()
          .eq('business_date', date);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('getDailyProductSummary error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDailySectionTotals(String date) async {
    if (!_supabase.isInitialized) return [];
    try {
      final res = await _supabase.client
          .from('daily_section_totals')
          .select()
          .eq('business_date', date);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('getDailySectionTotals error: $e');
      return [];
    }
  }
}
