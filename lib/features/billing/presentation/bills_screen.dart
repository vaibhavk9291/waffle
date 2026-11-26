import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/printer_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../billing/presentation/cart_provider.dart';
import '../../history/presentation/history_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../settings/data/settings_repository.dart';
import '../data/billing_repository.dart';
import '../domain/bill.dart';

class TodayBillsNotifier extends StateNotifier<AsyncValue<List<Bill>>> {
  TodayBillsNotifier() : super(const AsyncLoading()) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final bills = await BillingRepository().getTodayBills();
      state = AsyncData(bills);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void clearList() {
    state = const AsyncData([]);
  }
}

final todayBillsProvider = StateNotifierProvider<TodayBillsNotifier, AsyncValue<List<Bill>>>((ref) {
  return TodayBillsNotifier();
});

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  void _clearBillsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Clear Today's Bills?", style: AppTextStyles.title.copyWith(fontSize: 18)),
        content: Text(
          "This will clear today's saved bills and reset the counter back to ₹0.",
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              // 1. Instantly zero out UI state
              ref.read(cartProvider.notifier).clearCart();
              ref.read(todayBillsProvider.notifier).clearList();
              ref.read(todayTotalProvider.notifier).resetToZero();
              ref.invalidate(historyTotalsProvider);

              // 2. Clear from storage & database
              await BillingRepository().clearSalesData(allDates: false);
              ref.read(todayBillsProvider.notifier).refresh();
              ref.read(todayTotalProvider.notifier).refresh();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Today's bills cleared successfully"),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Clear Bills'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(todayBillsProvider);

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
                    Text("Today's Bills", style: AppTextStyles.title),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                          tooltip: 'Clear bills',
                          onPressed: () => _clearBillsDialog(context, ref),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                          onPressed: () => ref.read(todayBillsProvider.notifier).refresh(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: billsAsync.when(
                  data: (bills) {
                    if (bills.isEmpty) {
                      return Center(
                        child: Text(
                          'No bills generated yet today',
                          style: AppTextStyles.caption.copyWith(fontSize: 15),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: bills.length,
                      itemBuilder: (context, index) {
                        final bill = bills[index];
                        return _buildBillCard(context, bill);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error loading bills: $e', style: AppTextStyles.body),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillCard(BuildContext context, Bill bill) {
    final isVoid = bill.isVoid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: isVoid ? Border.all(color: AppColors.danger.withValues(alpha: 0.5)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bill #${bill.billNo}',
                style: AppTextStyles.cardTitle.copyWith(
                  color: isVoid ? AppColors.danger : AppColors.primary,
                  decoration: isVoid ? TextDecoration.lineThrough : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isVoid
                      ? AppColors.danger.withValues(alpha: 0.2)
                      : AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isVoid ? 'VOID' : bill.paymentMode.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: isVoid ? AppColors.danger : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('hh:mm a').format(bill.createdAt),
                style: AppTextStyles.caption,
              ),
              Text(
                '₹${bill.total}',
                style: AppTextStyles.title.copyWith(
                  color: isVoid ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (bill.items.isNotEmpty) ...[
            const Divider(color: AppColors.hairline, height: 16),
            ...bill.items.map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${i.qty}x ${i.productName}', style: AppTextStyles.caption),
                      Text('₹${i.lineTotal}', style: AppTextStyles.caption),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Reprint Button
              GestureDetector(
                onTap: () async {
                  final settings = await SettingsRepository().getSettings();
                  await PrinterService.instance.printReceipt(
                    settings: settings,
                    bill: bill,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.print_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Reprint',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
