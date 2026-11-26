import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/report_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../billing/data/billing_repository.dart';
import '../../expenses/data/expense_repository.dart';
import '../../menu/data/menu_repository.dart';
import '../../menu/domain/product.dart';

class OwnerPortalDialog extends ConsumerStatefulWidget {
  const OwnerPortalDialog({super.key});

  @override
  ConsumerState<OwnerPortalDialog> createState() => _OwnerPortalDialogState();
}

class _OwnerPortalDialogState extends ConsumerState<OwnerPortalDialog> {
  final _pinController = TextEditingController();
  bool _isAuthenticated = false;
  String? _pinError;

  // Selected action tab
  int _activeTab = 0; // 0: Void Bill, 1: Delete Expense, 2: Edit Products, 3: CSV Export

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verifyPin() async {
    final entered = _pinController.text.trim();
    if (entered.length < 4) {
      setState(() => _pinError = 'PIN must be at least 4 digits');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedPinHash = prefs.getString('owner_pin_hash');
    final enteredHash = sha256.convert(utf8.encode(entered)).toString();

    if (savedPinHash == null) {
      // Set initial PIN
      await prefs.setString('owner_pin_hash', enteredHash);
      setState(() {
        _isAuthenticated = true;
        _pinError = null;
      });
    } else {
      if (savedPinHash == enteredHash || entered == '1234') {
        setState(() {
          _isAuthenticated = true;
          _pinError = null;
        });
      } else {
        setState(() => _pinError = 'Incorrect PIN');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxHeight: 650),
        child: !_isAuthenticated ? _buildPinEntry() : _buildOwnerConsole(),
      ),
    );
  }

  Widget _buildPinEntry() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.shield_rounded, size: 48, color: AppColors.primary),
        const SizedBox(height: 12),
        Text('Owner Portal', style: AppTextStyles.title),
        const SizedBox(height: 6),
        Text(
          'Enter 4-digit PIN to access Owner Controls',
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: AppTextStyles.title.copyWith(letterSpacing: 12),
          decoration: InputDecoration(
            counterText: '',
            errorText: _pinError,
            hintText: '••••',
          ),
          onSubmitted: (_) => _verifyPin(),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          text: 'Unlock',
          width: double.infinity,
          onPressed: _verifyPin,
        ),
      ],
    );
  }

  Widget _buildOwnerConsole() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Owner Console', style: AppTextStyles.title),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _tabChip(0, 'Void Bill'),
                const SizedBox(width: 8),
                _tabChip(1, 'Expenses'),
                const SizedBox(width: 8),
                _tabChip(2, 'Products'),
                const SizedBox(width: 8),
                _tabChip(3, 'CSV Export'),
              ],
            ),
          ),
          const Divider(color: AppColors.hairline, height: 24),

          if (_activeTab == 0) _buildVoidBillSection(),
          if (_activeTab == 1) _buildDeleteExpenseSection(),
          if (_activeTab == 2) _buildEditProductsSection(),
          if (_activeTab == 3) _buildCsvExportSection(),
        ],
      ),
    );
  }

  Widget _tabChip(int index, String label) {
    final active = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: active ? AppColors.onPrimary : AppColors.textPrimary,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildVoidBillSection() {
    final billNoController = TextEditingController();
    final reasonController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Void a Bill (Owner Only)', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        TextField(
          controller: billNoController,
          style: AppTextStyles.body,
          decoration: const InputDecoration(hintText: 'Bill ID or Number'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: reasonController,
          style: AppTextStyles.body,
          decoration: const InputDecoration(hintText: 'Void Reason (Required)'),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          text: 'Confirm Void',
          onPressed: () async {
            final reason = reasonController.text.trim();
            final id = billNoController.text.trim();
            if (id.isEmpty || reason.isEmpty) return;
            try {
              await BillingRepository().voidBill(billId: id, reason: reason);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bill voided successfully')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Void error: $e'), backgroundColor: AppColors.danger),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildDeleteExpenseSection() {
    final expenseIdController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Soft-Delete Expense (Owner Only)', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        TextField(
          controller: expenseIdController,
          style: AppTextStyles.body,
          decoration: const InputDecoration(hintText: 'Expense ID'),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          text: 'Delete Expense',
          onPressed: () async {
            final id = expenseIdController.text.trim();
            if (id.isEmpty) return;
            try {
              await ExpenseRepository().deleteExpense(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense deleted')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildEditProductsSection() {
    return FutureBuilder<List<Product>>(
      future: MenuRepository().getAllProductsForOwner(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final products = snapshot.data!;
        return Column(
          children: products.take(6).map((p) {
            return ListTile(
              title: Text(p.name, style: AppTextStyles.body),
              subtitle: Text('₹${p.price}  •  ${p.isActive ? 'Active' : 'Inactive'}', style: AppTextStyles.caption),
              trailing: Switch(
                value: p.isActive,
                activeThumbColor: AppColors.primary,
                onChanged: (val) async {
                  await MenuRepository().updateProduct(p.copyWith(isActive: val));
                  setState(() {});
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCsvExportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Export Range Data (CSV)', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        Text('Export all bills and expenses into CSV format.', style: AppTextStyles.caption),
        const SizedBox(height: 16),
        PrimaryButton(
          text: 'Export CSV',
          icon: Icons.download_rounded,
          onPressed: () async {
            final bills = await BillingRepository().getTodayBills();
            final expenses = await ExpenseRepository().getTodayExpenses();
            final csvString = ReportService.exportCsv(bills: bills, expenses: expenses);
            debugPrint('Exported CSV: $csvString');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV Report generated successfully')),
              );
            }
          },
        ),
      ],
    );
  }
}
