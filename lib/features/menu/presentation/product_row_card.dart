import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../billing/presentation/cart_provider.dart';
import '../../history/data/history_repository.dart';
import '../domain/product.dart';

final todayProductSummaryProvider =
    FutureProvider<Map<String, int>>((ref) async {
  try {
    final todayTotal = await HistoryRepository().getTodayTotal();
    final list = await HistoryRepository()
        .getDailyProductSummary(todayTotal.businessDate);
    final map = <String, int>{};
    for (final item in list) {
      final prodId = item['product_id']?.toString() ?? '';
      final revenue = (item['revenue'] as num?)?.toInt() ?? 0;
      if (prodId.isNotEmpty) {
        map[prodId] = revenue;
      }
    }
    return map;
  } catch (_) {
    return <String, int>{};
  }
});

class ProductRowCard extends ConsumerWidget {
  final Product product;

  const ProductRowCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final count = cart.getQuantity(product.id);
    final summaryAsync = ref.watch(todayProductSummaryProvider);

    // Calculate today's sales for this product (stored sales + live in-cart)
    final storedTodayRevenue = summaryAsync.value?[product.id] ?? 0;
    final liveProductTodayRevenue =
        storedTodayRevenue + (count * product.price);

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                      'Today: ₹$liveProductTodayRevenue',
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

          // Stepper
          QuantityStepper(
            count: count,
            onAdd: () => ref.read(cartProvider.notifier).addItem(product),
            onRemove: () => ref.read(cartProvider.notifier).removeItem(product),
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
