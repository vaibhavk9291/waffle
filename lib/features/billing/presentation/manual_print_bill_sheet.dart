import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/printer_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../home/presentation/home_screen.dart';
import '../../menu/domain/product.dart';
import '../../menu/presentation/section_screen.dart';
import '../../settings/data/settings_repository.dart';
import '../data/billing_repository.dart';
import '../domain/bill.dart';
import '../domain/cart_item.dart';
import 'bills_screen.dart';

class ManualPrintBillSheet extends ConsumerStatefulWidget {
  const ManualPrintBillSheet({super.key});

  @override
  ConsumerState<ManualPrintBillSheet> createState() => _ManualPrintBillSheetState();
}

class _ManualPrintBillSheetState extends ConsumerState<ManualPrintBillSheet> {
  final Map<String, int> _selected = {}; // productId -> quantity
  String _paymentMode = 'cash';
  bool _isPrinting = false;
  String _searchQuery = '';
  String _filterSection = 'all'; // 'all', 'choc', 'waffle'

  int _getSubtotal(List<Product> products) {
    int total = 0;
    for (final p in products) {
      final qty = _selected[p.id] ?? 0;
      total += p.price * qty;
    }
    return total;
  }

  int _getTotalItems() {
    int count = 0;
    for (final qty in _selected.values) {
      count += qty;
    }
    return count;
  }

  void _onPrint(List<Product> allProducts) async {
    final subtotal = _getSubtotal(allProducts);
    if (subtotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 product to print a bill'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isPrinting = true);

    try {
      final cartItems = <CartItem>[];
      for (final p in allProducts) {
        final qty = _selected[p.id] ?? 0;
        if (qty > 0) {
          cartItems.add(CartItem(product: p, qty: qty));
        }
      }

      // 1. Create bill in database and local cache
      final res = await BillingRepository().createBill(
        items: cartItems,
        discount: 0,
        paymentMode: _paymentMode,
      );

      final billNo = res['bill_no'] ?? 0;
      final billTotal = res['total'] ?? subtotal;

      // 2. Refresh dashboard totals
      ref.read(todayTotalProvider.notifier).refresh();
      ref.read(todayBillsProvider.notifier).refresh();

      // 3. Print receipt via thermal printer
      final settings = await SettingsRepository().getSettings();
      final bill = Bill(
        id: res['id'] ?? '',
        billNo: billNo,
        businessDate: res['business_date'] ?? '',
        subtotal: subtotal,
        discount: 0,
        total: billTotal,
        paymentMode: _paymentMode,
        status: 'paid',
        createdAt: DateTime.now(),
        items: cartItems
            .map((i) => BillItem(
                  id: '',
                  billId: res['id'] ?? '',
                  productId: i.product.id,
                  productName: i.product.name,
                  unitPrice: i.product.price,
                  qty: i.qty,
                  lineTotal: i.lineTotal,
                ))
            .toList(),
      );

      await PrinterService.instance.printReceipt(
        settings: settings,
        bill: bill,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill #$billNo printed successfully (₹$billTotal)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing bill: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Print Bill (Manual)', style: AppTextStyles.title.copyWith(fontSize: 18)),
                        Text('Select products to generate receipt', style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search and filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'Search waffle or chocolate bowl...',
                    hintStyle: AppTextStyles.caption,
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.hairline),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _filterChip('all', 'All Products'),
                    const SizedBox(width: 8),
                    _filterChip('choc', 'Chocolate Bowls'),
                    const SizedBox(width: 8),
                    _filterChip('waffle', 'Waffles'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.hairline, height: 16),

          // Products List
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filtered = products.where((p) {
                  final matchesSearch = _searchQuery.isEmpty || p.name.toLowerCase().contains(_searchQuery);
                  final matchesSection = _filterSection == 'all'
                      ? true
                      : _filterSection == 'choc'
                          ? p.name.toLowerCase().contains('bowl')
                          : p.name.toLowerCase().contains('waffle');
                  return matchesSearch && matchesSection;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text('No products found', style: AppTextStyles.caption),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    final qty = _selected[product.id] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: qty > 0 ? AppColors.primary : AppColors.hairline,
                          width: qty > 0 ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 50,
                              height: 50,
                              color: AppColors.surfaceHigh,
                              child: Image.asset(
                                'assets/products/${product.resolvedImageKey}.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.fastfood_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '₹${product.price}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          QuantityStepper(
                            count: qty,
                            onAdd: () {
                              setState(() {
                                _selected[product.id] = qty + 1;
                              });
                            },
                            onRemove: () {
                              if (qty > 0) {
                                setState(() {
                                  if (qty == 1) {
                                    _selected.remove(product.id);
                                  } else {
                                    _selected[product.id] = qty - 1;
                                  }
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Error loading products: $e')),
            ),
          ),

          // Bottom Action Bar
          productsAsync.when(
            data: (products) {
              final subtotal = _getSubtotal(products);
              final totalItems = _getTotalItems();

              return Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$totalItems items selected',
                                style: AppTextStyles.caption,
                              ),
                              Text(
                                '₹$subtotal',
                                style: AppTextStyles.title.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                          // Payment mode toggle
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                _modeButton('cash', 'Cash'),
                                _modeButton('upi', 'UPI / Online'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isPrinting || subtotal <= 0 ? null : () => _onPrint(products),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            disabledBackgroundColor: AppColors.surfaceHigh,
                          ),
                          child: _isPrinting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.print_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Print Thermal Bill',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _filterSection == key;
    return GestureDetector(
      onTap: () => setState(() => _filterSection = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.hairline),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _modeButton(String key, String label) {
    final isSelected = _paymentMode == key;
    return GestureDetector(
      onTap: () => setState(() => _paymentMode = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.primaryButton : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
