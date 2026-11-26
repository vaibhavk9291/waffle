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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh.withValues(alpha: canRemove ? 1.0 : 0.3),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.remove,
              size: 20,
              color: AppColors.textPrimary.withValues(alpha: canRemove ? 1.0 : 0.3),
            ),
          ),
        ),

        // Count with AnimatedSwitcher
        Container(
          constraints: const BoxConstraints(minWidth: 38),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
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
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: AppGradients.primaryButton,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.buttonGlow,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.add,
              size: 20,
              color: AppColors.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepperButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool enabled;

  const _StepperButton({
    required this.child,
    required this.onTap,
    required this.enabled,
  });

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.enabled) _anim.forward();
      },
      onTapUp: (_) {
        if (widget.enabled) _anim.reverse();
      },
      onTapCancel: () => _anim.reverse(),
      onTap: widget.enabled ? widget.onTap : null,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
