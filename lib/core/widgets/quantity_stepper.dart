import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/gradients.dart';
import '../theme/text_styles.dart';

class QuantityStepper extends StatelessWidget {
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const QuantityStepper({
    super.key,
    required this.count,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final canRemove = count > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minus Button
        _StepperButton(
          enabled: canRemove,
          onTap: () {
            if (canRemove) {
              HapticFeedback.lightImpact();
              onRemove();
            }
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh.withValues(alpha: canRemove ? 1.0 : 0.3),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.remove,
              size: 18,
              color: AppColors.textPrimary.withValues(alpha: canRemove ? 1.0 : 0.3),
            ),
          ),
        ),

        // Count with AnimatedSwitcher and FittedBox to prevent any pixel overflow
        Container(
          constraints: const BoxConstraints(minWidth: 26, maxWidth: 40),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Text(
                '$count',
                key: ValueKey<int>(count),
                style: AppTextStyles.cardTitle.copyWith(
                  color: count > 0 ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),

        // Plus Button
        _StepperButton(
          enabled: true,
          onTap: () {
            HapticFeedback.lightImpact();
            onAdd();
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              gradient: AppGradients.primaryButton,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.buttonGlow,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.add,
              size: 18,
              color: AppColors.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  const _StepperButton({
    required this.enabled,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        splashColor: AppColors.primary.withValues(alpha: 0.2),
        highlightColor: AppColors.primary.withValues(alpha: 0.1),
        child: child,
      ),
    );
  }
}
