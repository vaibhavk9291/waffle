import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/live_chip.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../billing/data/billing_repository.dart';
import '../../billing/presentation/bills_screen.dart';
import '../../billing/presentation/cart_provider.dart';
import '../../billing/presentation/manual_print_bill_sheet.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/domain/expense.dart';
import '../../expenses/presentation/expense_sheet.dart';
import '../../history/data/history_repository.dart';
import '../../history/domain/daily_total.dart';
import '../../history/presentation/history_screen.dart';
import '../../menu/data/menu_repository.dart';
import '../../menu/domain/product.dart';
import '../../menu/domain/section.dart';
import '../../menu/presentation/section_screen.dart';
import '../../owner/presentation/owner_portal_dialog.dart';

final sectionsProvider = FutureProvider<List<Section>>((ref) async {
  return MenuRepository().getSections();
});

class TodayTotalNotifier extends StateNotifier<AsyncValue<DailyTotal>> {
  TodayTotalNotifier() : super(const AsyncLoading()) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final total = await HistoryRepository().getTodayTotal();
      state = AsyncData(total);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void addQuickSale(Product product, int qty) {
    state.whenData((current) {
      state = AsyncData(current.copyWith(
        billsCount: current.billsCount + 1,
        itemsSold: current.itemsSold + qty,
        grossRevenue: current.grossRevenue + (product.price * qty),
        net: current.net + (product.price * qty),
      ));
    });
  }

  void removeQuickSale(Product product, int qty) {
    state.whenData((current) {
      state = AsyncData(current.copyWith(
        billsCount: (current.billsCount - 1).clamp(0, double.infinity).toInt(),
        itemsSold: (current.itemsSold - qty).clamp(0, double.infinity).toInt(),
        grossRevenue: (current.grossRevenue - (product.price * qty)).clamp(0, double.infinity).toInt(),
        net: (current.net - (product.price * qty)).clamp(0, double.infinity).toInt(),
      ));
    });
  }

  void resetToZero() {
    final today = SupabaseService.instance.currentISTDate;
    state = AsyncData(DailyTotal.empty(today));
  }
}

final todayTotalProvider = StateNotifierProvider<TodayTotalNotifier, AsyncValue<DailyTotal>>((ref) {
  return TodayTotalNotifier();
});

final todayExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  return ExpenseRepository().getTodayExpenses();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openManualPrintBillSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ManualPrintBillSheet(),
    );
  }

  void _resetTodayCounterDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Reset Counter to ₹0?",
            style: AppTextStyles.title.copyWith(fontSize: 18)),
        content: Text(
          "Do you want to reset today's sales counter back to ₹0 and start fresh?",
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
              // 1. Immediately & synchronously snap UI to zero
              ref.read(cartProvider.notifier).clearCart();
              ref.read(todayTotalProvider.notifier).resetToZero();
              ref.read(todayBillsProvider.notifier).clearList();
              ref.invalidate(todayExpensesProvider);
              ref.invalidate(historyTotalsProvider);

              // 2. Perform background storage and database wipe
              await BillingRepository().clearSalesData(allDates: false);
              ref.read(todayTotalProvider.notifier).refresh();
              ref.read(todayBillsProvider.notifier).refresh();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Sales counter reset to ₹0"),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Reset to ₹0'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final sectionsAsync = ref.watch(sectionsProvider);
    final todayTotalAsync = ref.watch(todayTotalProvider);
    final expensesAsync = ref.watch(todayExpensesProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.screenBackground,
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceHigh,
            onRefresh: () async {
              ref.read(todayTotalProvider.notifier).refresh();
              ref.invalidate(todayExpensesProvider);
              ref.invalidate(sectionsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onLongPress: () {
                        // Secret Owner-only hidden layer trigger per Phase 5
                        showDialog(
                          context: context,
                          builder: (_) => const OwnerPortalDialog(),
                        );
                      },
                      child: Image.asset(
                        'assets/branding/logo_shrimant.png',
                        height: 42,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.icecream_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Namaste,',
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                          Text(
                            authState.profile?.displayName ?? 'Counter Staff',
                            style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _openManualPrintBillSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.hairline),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.print_rounded, size: 16, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('Bill', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const LiveChip(),
                    const SizedBox(width: 10),
                    // Logout button
                    GestureDetector(
                      onTap: () => ref.read(authProvider.notifier).signOut(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceHigh,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Top Dashboard Action: Print Bill (Manual)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.hairline),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openManualPrintBillSheet(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppGradients.primaryButton,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.print_rounded,
                                color: AppColors.onPrimary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Print Bill (Manual)',
                                    style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                                  ),
                                  Text(
                                    'Add products manually & print thermal receipt',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.hairline),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Print',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Hero Summary Card: directly reflects current added items + today's sales
                todayTotalAsync.when(
                  data: (total) => _buildHeroCard(context, ref, total),
                  loading: () => _buildHeroSkeleton(),
                  error: (_, __) => _buildHeroCard(context, ref, DailyTotal.empty('Today')),
                ),
                const SizedBox(height: 24),

                // Section title: Menu
                Text('Menu', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 12),

                // Two Section Tiles: Chocolate Bowl & Waffle
                sectionsAsync.when(
                  data: (sections) => _buildSectionTiles(context, sections),
                  loading: () => const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // Today's Expenses Row Card
                _buildExpensesCard(context, ref, expensesAsync),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, WidgetRef ref, DailyTotal total) {
    // Whenever products are added, they are directly added to the total amount displayed above!
    final liveGross = total.grossRevenue;
    final liveItems = total.itemsSold;
    final liveNet = liveGross - total.expensesTotal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppGradients.primaryButton,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.buttonGlow,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Reset button shortcut top right
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () => _resetTodayCounterDialog(context, ref),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restart_alt_rounded,
                  size: 20,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Sales",
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Text(
                  '₹$liveGross',
                  key: ValueKey<int>(liveGross),
                  style: AppTextStyles.displayPrice,
                ),
              ),
              const SizedBox(height: 18),
              // Mini stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _miniStat('Items', '$liveItems'),
                  Container(width: 1, height: 24, color: AppColors.onPrimary.withValues(alpha: 0.2)),
                  _miniStat('Expenses', '₹${total.expensesTotal}'),
                  Container(width: 1, height: 24, color: AppColors.onPrimary.withValues(alpha: 0.2)),
                  _miniStat('Net', '₹$liveNet'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.onPrimary.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.cardTitle.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSkeleton() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildSectionTiles(BuildContext context, List<Section> sections) {
    final choc = sections.firstWhere(
      (s) => s.name.toLowerCase().contains('choc'),
      orElse: () => const Section(id: '11111111-1111-1111-1111-111111111111', name: 'Chocolate Bowl', sortOrder: 1),
    );
    final waffle = sections.firstWhere(
      (s) => s.name.toLowerCase().contains('waffle'),
      orElse: () => const Section(id: '22222222-2222-2222-2222-222222222222', name: 'Waffle', sortOrder: 2),
    );

    return Column(
      children: [
        _sectionTile(
          context: context,
          section: choc,
          gradient: AppGradients.chocolateTile,
          icon: Icons.soup_kitchen_rounded,
          countText: '9 products',
        ),
        const SizedBox(height: 14),
        _sectionTile(
          context: context,
          section: waffle,
          gradient: AppGradients.waffleTile,
          icon: Icons.grid_view_rounded,
          countText: '13 products',
        ),
      ],
    );
  }

  Widget _sectionTile({
    required BuildContext context,
    required Section section,
    required LinearGradient gradient,
    required IconData icon,
    required String countText,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SectionScreen(section: section),
          ),
        );
      },
      child: Container(
        height: 104,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(section.name, style: AppTextStyles.title),
                  const SizedBox(height: 4),
                  Text(countText, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 44),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Expense>> expensesAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Expenses", style: AppTextStyles.sectionTitle),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const ExpenseSheet(),
                  ).then((_) {
                    ref.invalidate(todayExpensesProvider);
                    ref.read(todayTotalProvider.notifier).refresh();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Add expense',
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
          const SizedBox(height: 12),
          expensesAsync.when(
            data: (expenses) {
              if (expenses.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No expenses recorded today',
                    style: AppTextStyles.caption,
                  ),
                );
              }
              return Column(
                children: expenses.take(5).map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            e.note,
                            style: AppTextStyles.body,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '- ₹${e.amount}',
                          style: AppTextStyles.cardTitle.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
