import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../billing/data/billing_repository.dart';
import '../../billing/presentation/bills_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../domain/product.dart';

class ProductRowCard extends ConsumerWidget {
  final Product product;

  const ProductRowCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(todayBillsProvider).value ?? [];
    final count = bills
        .where((b) => !b.isVoid)
        .fold<int>(0, (sum, b) => sum + b.items.where((it) => it.productId == product.id).fold<int>(0, (iSum, it) => iSum + it.qty));
    final todayProductRevenue = count * product.price;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // 72x72 rounded thumbnail on a tinted square
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 72,
                  height: 72,
                  color: AppColors.surfaceHigh,
                  child: Image.asset(
                    'assets/products/${product.resolvedImageKey}.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackIcon(product),
                  ),
                ),
              ),
              if (product.isNew)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'NEW',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Name, price caption, and today's sales caption
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTextStyles.cardTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${product.price} each',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Today: $count sold (₹$todayProductRevenue)',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stepper: directly adds to sell counter
          QuantityStepper(
            count: count,
            onAdd: () async {
              // 1. Optimistic immediate update to sales counter
              ref.read(todayTotalProvider.notifier).addQuickSale(product, 1);

              // 2. Direct sale in repository
              await BillingRepository().createDirectProductSale(product: product, qty: 1);

              // 3. Keep providers in sync
              ref.read(todayBillsProvider.notifier).refresh();
              ref.read(todayTotalProvider.notifier).refresh();
            },
            onRemove: () async {
              if (count <= 0) return;

              // 1. Optimistic immediate update to sales counter
              ref.read(todayTotalProvider.notifier).removeQuickSale(product, 1);

              // 2. Void last sale of this product
              await BillingRepository().voidLastBillForProduct(product.id);

              // 3. Keep providers in sync
              ref.read(todayBillsProvider.notifier).refresh();
              ref.read(todayTotalProvider.notifier).refresh();
            },
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon(Product p) {
    final isWaffle = p.name.toLowerCase().contains('waffle');
    return Center(
      child: Icon(
        isWaffle ? Icons.grid_view_rounded : Icons.soup_kitchen_rounded,
        color: isWaffle ? AppColors.waffleGold : AppColors.chocolate,
        size: 36,
      ),
    );
  }
}
