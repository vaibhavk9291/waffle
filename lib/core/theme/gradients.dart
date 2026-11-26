import 'package:flutter/material.dart';
import 'colors.dart';

class AppGradients {
  AppGradients._();

  /// Screen background vertical gradient
  static const LinearGradient screenBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bgTop, AppColors.bgBottom],
  );

  /// Primary button / hero card diagonal yellow gradient
  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryDark],
  );

  /// Chocolate Bowl section tile diagonal gradient
  static const LinearGradient chocolateTile = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5A2D1D), Color(0xFF2E140E)],
  );

  /// Waffle section tile diagonal gradient
  static const LinearGradient waffleTile = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB8742A), Color(0xFF5A3410)],
  );

  /// Surface card gradient
  static const LinearGradient surfaceCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF331544), Color(0xFF240E30)],
  );
}
