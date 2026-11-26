import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/printer_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../billing/data/billing_repository.dart';
import '../../billing/domain/bill.dart';
import '../../billing/presentation/bills_screen.dart';
import '../../billing/presentation/cart_provider.dart';
import '../../history/presentation/history_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../data/settings_repository.dart';
import '../domain/shop_settings.dart';

final shopSettingsProvider = FutureProvider<ShopSettings>((ref) async {
  return SettingsRepository().getSettings();
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstinController = TextEditingController();
  final _footerController = TextEditingController();
  int _paperWidthMm = 58;
  bool _isSaving = false;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(shopSettingsProvider).value;
      if (settings != null) {
        _populate(settings);
      }
    });
  }

  void _populate(ShopSettings s) {
    _shopNameController.text = s.shopName;
    _addressController.text = s.address;
    _phoneController.text = s.phone;
    _gstinController.text = s.gstin ?? '';
    _footerController.text = s.receiptFooter;
    _paperWidthMm = s.paperWidthMm;
    setState(() {});
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final s = ShopSettings(
        id: 1,
        shopName: _shopNameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        gstin: _gstinController.text.trim().isEmpty ? null : _gstinController.text.trim(),
        receiptFooter: _footerController.text.trim(),
        paperWidthMm: _paperWidthMm,
      );
      await SettingsRepository().updateSettings(s);
      ref.invalidate(shopSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _testPrint() async {
    final settings = ShopSettings(
      id: 1,
      shopName: _shopNameController.text.trim().isEmpty ? 'Shrimant Street Food' : _shopNameController.text.trim(),
      address: _addressController.text.trim().isEmpty ? 'Counter No. 1, Pune' : _addressController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? '+91 9876543210' : _phoneController.text.trim(),
      gstin: _gstinController.text.trim(),
      receiptFooter: _footerController.text.trim().isEmpty ? 'Thank you! Visit again.' : _footerController.text.trim(),
      paperWidthMm: _paperWidthMm,
    );

    final mockBill = Bill(
      id: 'test-print',
      billNo: 101,
      businessDate: 'Today',
      subtotal: 190,
      discount: 20,
      total: 170,
      paymentMode: 'upi',
      status: 'paid',
      createdAt: DateTime.now(),
      items: const [
        BillItem(id: '1', billId: 'test', productName: 'Dark Chocolate Bowl', unitPrice: 70, qty: 1, lineTotal: 70),
        BillItem(id: '2', billId: 'test', productName: 'Triple Chocolate Waffle', unitPrice: 100, qty: 1, lineTotal: 100),
      ],
    );

    await PrinterService.instance.printReceipt(
      settings: settings,
      bill: mockBill,
      cashierName: 'Counter 1',
    );
  }

  void _confirmResetData({required bool allDates}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          allDates ? 'Wipe All Data Completely?' : "Reset Today's Sales to ₹0?",
          style: AppTextStyles.title.copyWith(fontSize: 18),
        ),
        content: Text(
          allDates
              ? 'This will delete all saved bills, expenses, and counter records from storage so you can start completely from scratch. This action cannot be undone.'
              : "This will reset today's sales counter, clear today's saved bills, and set the counter back to ₹0.",
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
              setState(() => _isResetting = true);

              // 1. Instantly & synchronously snap UI to zero
              ref.read(cartProvider.notifier).clearCart();
              ref.read(todayTotalProvider.notifier).resetToZero();
              ref.read(todayBillsProvider.notifier).clearList();
              ref.invalidate(todayExpensesProvider);
              ref.invalidate(historyTotalsProvider);

              try {
                // 2. Perform background storage and database wipe
                await BillingRepository().clearSalesData(allDates: allDates);
                ref.read(todayTotalProvider.notifier).refresh();
                ref.read(todayBillsProvider.notifier).refresh();
                ref.invalidate(historyTotalsProvider);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(allDates
                          ? 'All data wiped completely. Starting from scratch!'
                          : "Today's sales counter reset to ₹0"),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error resetting data: $e'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isResetting = false);
              }
            },
            child: Text(allDates ? 'Yes, Wipe Everything' : 'Yes, Reset to ₹0'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<ShopSettings>>(shopSettingsProvider, (_, next) {
      if (next.hasValue && next.value != null) {
        _populate(next.value!);
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.screenBackground,
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              Text('Settings', style: AppTextStyles.title),
              const SizedBox(height: 20),

              // Shop Details
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shop Details', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 14),
                    _field('Shop Name', _shopNameController),
                    const SizedBox(height: 12),
                    _field('Counter Address', _addressController),
                    const SizedBox(height: 12),
                    _field('Phone Number', _phoneController),
                    const SizedBox(height: 12),
                    _field('GSTIN (Optional)', _gstinController),
                    const SizedBox(height: 12),
                    _field('Receipt Footer Note', _footerController),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Printer Settings
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thermal Printer Settings', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Paper Width', style: AppTextStyles.body),
                        Row(
                          children: [
                            _widthOption(58, '58 mm'),
                            const SizedBox(width: 8),
                            _widthOption(80, '80 mm'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: _testPrint,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Test Print Receipt'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Data Management & Reset Option (Keyphone option to start from scratch)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.delete_sweep_rounded, color: AppColors.danger, size: 22),
                        const SizedBox(width: 8),
                        Text('Reset Sales & Clear Data', style: AppTextStyles.sectionTitle.copyWith(color: AppColors.danger)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Clear saved amounts or wipe data completely to restart counter testing from scratch.',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isResetting ? null : () => _confirmResetData(allDates: false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text("Reset Today (₹0)"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isResetting ? null : () => _confirmResetData(allDates: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Wipe All Data'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                text: 'Save Settings',
                isLoading: _isSaving,
                width: double.infinity,
                onPressed: _saveSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            hintText: 'Enter $label',
          ),
        ),
      ],
    );
  }

  Widget _widthOption(int width, String label) {
    final selected = _paperWidthMm == width;
    return GestureDetector(
      onTap: () => setState(() => _paperWidthMm = width),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? AppColors.onPrimary : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
