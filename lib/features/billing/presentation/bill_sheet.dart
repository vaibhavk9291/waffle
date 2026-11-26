import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/printer_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../home/presentation/home_screen.dart';
import '../../settings/data/settings_repository.dart';
import '../data/billing_repository.dart';
import '../domain/bill.dart';
import 'bills_screen.dart';
import 'cart_provider.dart';

class BillSheet extends ConsumerStatefulWidget {
  const BillSheet({super.key});

  @override
  ConsumerState<BillSheet> createState() => _BillSheetState();
}

class _BillSheetState extends ConsumerState<BillSheet> {
  final _discountController = TextEditingController(text: '0');
  String _paymentMode = 'cash'; // 'cash' | 'upi'
  bool _isLoading = false;

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  int get _discount {
    return int.tryParse(_discountController.text) ?? 0;
  }

  void _saveBill({bool printReceipt = false}) async {
    final cart = ref.read(cartProvider);
    if (cart.itemList.isEmpty) return;

    if (_discount > cart.subtotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Discount cannot exceed subtotal!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await BillingRepository().createBill(
        items: cart.itemList,
        discount: _discount,
        paymentMode: _paymentMode,
      );

      final billNo = res['bill_no'] ?? 0;
      final billTotal = res['total'] ?? (cart.subtotal - _discount);

      // Refresh today's totals
      ref.read(todayTotalProvider.notifier).refresh();
      ref.read(todayBillsProvider.notifier).refresh();

      if (printReceipt) {
        final settings = await SettingsRepository().getSettings();
        final bill = Bill(
          id: res['id'] ?? '',
          billNo: billNo,
          businessDate: res['business_date'] ?? '',
          subtotal: cart.subtotal,
          discount: _discount,
          total: billTotal,
          paymentMode: _paymentMode,
          status: 'paid',
          createdAt: DateTime.now(),
          items: cart.itemList
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
      }

      // Clear cart
      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill #$billNo saved successfully (₹$billTotal)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving bill: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final grandTotal = (cart.subtotal - _discount).clamp(0, double.infinity).toInt();

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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

            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Current Bill', style: AppTextStyles.title),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Item rows
            ...cart.itemList.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(item.product.name, style: AppTextStyles.body),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${item.qty} × ₹${item.product.price}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    Text(
                      '₹${item.lineTotal}',
                      style: AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            }),

            const Divider(color: AppColors.hairline, height: 28),

            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: AppTextStyles.caption.copyWith(fontSize: 14)),
                Text('₹${cart.subtotal}', style: AppTextStyles.cardTitle),
              ],
            ),
            const SizedBox(height: 12),

            // Discount input
            Row(
              children: [
                Text('Discount (₹)', style: AppTextStyles.caption.copyWith(fontSize: 14)),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.cardTitle.copyWith(color: AppColors.danger),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        fillColor: AppColors.surface,
                        hintText: '0',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Mode Toggle
            Row(
              children: [
                Text('Payment Mode', style: AppTextStyles.caption.copyWith(fontSize: 14)),
                const Spacer(),
                _modeChip('cash', 'Cash'),
                const SizedBox(width: 8),
                _modeChip('upi', 'UPI / QR'),
              ],
            ),
            const SizedBox(height: 20),

            // Grand Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Grand Total', style: AppTextStyles.sectionTitle),
                Text(
                  '₹$grandTotal',
                  style: AppTextStyles.displayPriceDark.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _saveBill(printReceipt: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.hairline),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save bill'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: 'Save & print',
                    icon: Icons.print_rounded,
                    isLoading: _isLoading,
                    onPressed: () => _saveBill(printReceipt: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeChip(String mode, String label) {
    final selected = _paymentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _paymentMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? AppColors.onPrimary : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
