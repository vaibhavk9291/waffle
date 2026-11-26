import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/expense_repository.dart';

class ExpenseSheet extends StatefulWidget {
  const ExpenseSheet({super.key});

  @override
  State<ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<ExpenseSheet> {
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() async {
    final note = _noteController.text.trim();
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;

    if (note.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid note and amount'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ExpenseRepository().addExpense(note: note, amount: amount);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense added: $note (₹$amount)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add expense: $e'),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Text('Add Expense', style: AppTextStyles.title),
          const SizedBox(height: 18),

          // Note Field
          TextField(
            controller: _noteController,
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              hintText: 'Expense note (e.g. Milk, Chocolate, Gas)',
              prefixIcon: Icon(Icons.edit_note_rounded, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 14),

          // Amount Field with ₹ prefix
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: AppTextStyles.cardTitle.copyWith(color: AppColors.danger),
            decoration: const InputDecoration(
              hintText: 'Amount',
              prefixText: '₹ ',
              prefixStyle: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Add Expense Pill Button
          PrimaryButton(
            text: 'Add expense',
            width: double.infinity,
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
