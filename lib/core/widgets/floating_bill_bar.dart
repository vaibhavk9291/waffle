import 'package:flutter/material.dart';

/// Deprecated: checkout bar removed per simplification requirement.
class FloatingBillBar extends StatelessWidget {
  final VoidCallback? onCheckout;

  const FloatingBillBar({
    super.key,
    this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
