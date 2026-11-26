import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/billing/domain/bill.dart';
import '../../features/expenses/domain/expense.dart';
import '../../features/history/domain/daily_total.dart';

class ReportService {
  ReportService._();

  /// Share daily summary report (e.g. to WhatsApp) as required in Phase 4
  static Future<void> shareDailyReport({
    required String date,
    required DailyTotal totals,
    required List<Map<String, dynamic>> sectionTotals,
    required List<Map<String, dynamic>> productSummary,
    required List<Expense> expenses,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('📋 *SHRIMANT STREET FOOD - DAILY REPORT*');
    buffer.writeln('📅 Date: $date');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💰 *Gross Revenue:* ₹${totals.grossRevenue}');
    buffer.writeln('🧾 *Bills Count:* ${totals.billsCount}');
    buffer.writeln('🍽️ *Items Sold:* ${totals.itemsSold}');
    if (totals.totalDiscount > 0) {
      buffer.writeln('🏷️ *Total Discounts:* ₹${totals.totalDiscount}');
    }
    buffer.writeln('💸 *Total Expenses:* ₹${totals.expensesTotal}');
    buffer.writeln('✨ *NET PROFIT:* ₹${totals.net}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');

    if (sectionTotals.isNotEmpty) {
      buffer.writeln('\n📊 *SECTION BREAKDOWN*');
      for (final s in sectionTotals) {
        buffer.writeln('• ${s['section_name']}: ${s['units_sold']} units | ₹${s['revenue']}');
      }
    }

    if (productSummary.isNotEmpty) {
      buffer.writeln('\n🧇 *TOP ITEMS*');
      for (final p in productSummary.take(10)) {
        buffer.writeln('• ${p['product_name']}: ${p['units_sold']} units (₹${p['revenue']})');
      }
    }

    if (expenses.isNotEmpty) {
      buffer.writeln('\n📉 *TODAY EXPENSES*');
      for (final e in expenses) {
        buffer.writeln('• ${e.note}: ₹${e.amount}');
      }
    }

    buffer.writeln('\n_Generated via Shrimant Counter App_');

    await Share.share(
      buffer.toString(),
      subject: 'Shrimant Daily Report ($date)',
    );
  }

  /// Export complete date range report as CSV as required in Phase 5
  static String exportCsv({
    required List<Bill> bills,
    required List<Expense> expenses,
  }) {
    final rows = <List<dynamic>>[];

    // Bills Section
    rows.add(['BILLS REPORT']);
    rows.add(['Bill No', 'Date', 'Subtotal', 'Discount', 'Total', 'Payment Mode', 'Status', 'Created At']);
    for (final b in bills) {
      rows.add([
        b.billNo,
        b.businessDate,
        b.subtotal,
        b.discount,
        b.total,
        b.paymentMode,
        b.status,
        b.createdAt.toIso8601String(),
      ]);
    }

    rows.add([]);
    rows.add(['EXPENSES REPORT']);
    rows.add(['Note', 'Amount', 'Date', 'Status', 'Created At']);
    for (final e in expenses) {
      rows.add([
        e.note,
        e.amount,
        e.businessDate,
        e.isDeleted ? 'Deleted' : 'Active',
        e.createdAt.toIso8601String(),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }
}
