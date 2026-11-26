import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/report_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../expenses/data/expense_repository.dart';
import '../data/history_repository.dart';
import '../domain/daily_total.dart';

final historyTotalsProvider = FutureProvider<List<DailyTotal>>((ref) async {
  return HistoryRepository().getLast30DaysTotals();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(historyTotalsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.screenBackground,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sales History', style: AppTextStyles.title),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                      onPressed: () => ref.invalidate(historyTotalsProvider),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: totalsAsync.when(
                  data: (totals) {
                    if (totals.isEmpty) {
                      return Center(
                        child: Text(
                          'No historical records found',
                          style: AppTextStyles.caption.copyWith(fontSize: 15),
                        ),
                      );
                    }

                    // Take first 7 days for chart
                    final last7Days = totals.take(7).toList().reversed.toList();

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      children: [
                        // 7-day revenue bar chart
                        _build7DayChart(last7Days),
                        const SizedBox(height: 20),

                        Text('Last 30 Days', style: AppTextStyles.sectionTitle),
                        const SizedBox(height: 12),

                        ...totals.map((t) => _buildDayCard(context, t)),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error loading history: $e', style: AppTextStyles.body),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _build7DayChart(List<DailyTotal> days) {
    if (days.isEmpty) return const SizedBox.shrink();

    final maxRevenue = days.fold<int>(1, (max, d) => d.grossRevenue > max ? d.grossRevenue : max);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('7-Day Revenue Trend', style: AppTextStyles.cardTitle),
          const SizedBox(height: 18),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final ratio = (day.grossRevenue / maxRevenue).clamp(0.08, 1.0);
                final isToday = day == days.last;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '₹${day.grossRevenue}',
                      style: TextStyle(
                        fontSize: 9,
                        color: isToday ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 24,
                      height: 80 * ratio,
                      decoration: BoxDecoration(
                        gradient: isToday ? AppGradients.primaryButton : null,
                        color: isToday ? null : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      day.businessDate.length >= 5
                          ? day.businessDate.substring(day.businessDate.length - 5)
                          : day.businessDate,
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, DailyTotal day) {
    return GestureDetector(
      onTap: () => _openDaySummary(context, day),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day.businessDate, style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text(
                  '${day.billsCount} bills | ${day.itemsSold} items sold',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${day.grossRevenue}',
                  style: AppTextStyles.title.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Net: ₹${day.net}',
                  style: AppTextStyles.caption.copyWith(
                    color: day.net >= 0 ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDaySummary(BuildContext context, DailyTotal day) async {
    final historyRepo = HistoryRepository();
    final expenseRepo = ExpenseRepository();

    final sectionTotals = await historyRepo.getDailySectionTotals(day.businessDate);
    final productSummary = await historyRepo.getDailyProductSummary(day.businessDate);
    final expenses = await expenseRepo.getTodayExpenses();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          decoration: const BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Report: ${day.businessDate}', style: AppTextStyles.title),
                    IconButton(
                      icon: const Icon(Icons.share_rounded, color: AppColors.primary),
                      onPressed: () {
                        ReportService.shareDailyReport(
                          date: day.businessDate,
                          totals: day,
                          sectionTotals: sectionTotals,
                          productSummary: productSummary,
                          expenses: expenses,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Gross: ₹${day.grossRevenue}  |  Expenses: ₹${day.expensesTotal}  |  Net: ₹${day.net}',
                  style: AppTextStyles.body.copyWith(color: AppColors.primary),
                ),
                const Divider(color: AppColors.hairline, height: 24),
                Text('Section Totals', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                ...sectionTotals.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s['section_name'] ?? '', style: AppTextStyles.body),
                          Text(
                            '${s['units_sold']} sold  •  ₹${s['revenue']}',
                            style: AppTextStyles.cardTitle,
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                Text('Products Breakdown', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                ...productSummary.map((p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(p['product_name'] ?? '', style: AppTextStyles.caption)),
                          Text(
                            '${p['units_sold']}x  •  ₹${p['revenue']}',
                            style: AppTextStyles.body,
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}
