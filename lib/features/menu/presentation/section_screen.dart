import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/floating_bill_bar.dart';
import '../../billing/presentation/bill_sheet.dart';
import '../../billing/presentation/cart_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../data/menu_repository.dart';
import '../domain/product.dart';
import '../domain/section.dart';
import 'product_row_card.dart';

final productsProvider = FutureProvider<List<Product>>((ref) async {
  return MenuRepository().getProducts();
});

class SectionScreen extends ConsumerWidget {
  final Section section;

  const SectionScreen({
    super.key,
    required this.section,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);
    final todayTotalAsync = ref.watch(todayTotalProvider);

    final storedGross = todayTotalAsync.value?.grossRevenue ?? 0;
    final liveTotalAmount = storedGross + cart.subtotal;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.screenBackground,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header with Total Sales Counter displayed directly above
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceHigh,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${section.name} Menu',
                            style: AppTextStyles.displayTitle.copyWith(fontSize: 20),
                          ),
                          Text(
                            'Total Sales: ₹$liveTotalAmount',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Live Cart Subtotal Badge
                    if (cart.subtotal > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryButton,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '+ ₹${cart.subtotal}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Product list
              Expanded(
                child: productsAsync.when(
                  data: (products) {
                    final sectionProducts =
                        products.where((p) => p.sectionId == section.id || products.length <= 15).toList();

                    // If Waffle section, group by sub_group
                    final standardProducts = sectionProducts
                        .where((p) => p.subGroup == null || p.subGroup!.isEmpty)
                        .toList();
                    final flavorProducts = sectionProducts
                        .where((p) => p.subGroup != null && p.subGroup!.isNotEmpty)
                        .toList();

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      children: [
                        ...standardProducts.map((p) => ProductRowCard(product: p)),
                        if (flavorProducts.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Waffle with Ice Cream Flavors',
                              style: AppTextStyles.sectionTitle.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          ...flavorProducts.map((p) => ProductRowCard(product: p)),
                        ],
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error loading products: $e', style: AppTextStyles.body),
                  ),
                ),
              ),

              // Floating Bill Bar
              FloatingBillBar(
                onCheckout: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const BillSheet(),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
