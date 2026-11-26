import 'package:flutter/foundation.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/expense.dart';

class ExpenseRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  Future<void> addExpense({required String note, required int amount}) async {
    if (!_supabase.isInitialized) {
      await OfflineSyncService.instance.queueExpense(note: note, amount: amount);
      return;
    }
    try {
      await _supabase.client.from('expenses').insert({
        'note': note,
        'amount': amount,
        'business_date': _supabase.currentISTDate,
      });
    } catch (e) {
      debugPrint('addExpense error, queueing locally: $e');
      await OfflineSyncService.instance.queueExpense(note: note, amount: amount);
    }
  }

  Future<List<Expense>> getTodayExpenses() async {
    if (!_supabase.isInitialized) return [];
    try {
      final today = _supabase.currentISTDate;
      final res = await _supabase.client
          .from('expenses')
          .select()
          .eq('business_date', today)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);
      return (res as List).map((e) => Expense.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getTodayExpenses error: $e');
      return [];
    }
  }

  Future<bool> deleteExpense(String expenseId) async {
    if (!_supabase.isInitialized) return false;
    try {
      final res = await _supabase.client.rpc('delete_expense', params: {
        'p_expense_id': expenseId,
      });
      return res as bool? ?? false;
    } catch (e) {
      debugPrint('deleteExpense error: $e');
      rethrow;
    }
  }
}
