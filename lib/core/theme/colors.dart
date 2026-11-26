import 'package:flutter/material.dart';

/// Design tokens from DESIGN.md
class AppColors {
  AppColors._();

  // Background gradients
  static const Color bgTop = Color(0xFF3A1250); // Plum
  static const Color bgBottom = Color(0xFF150820); // Near black plum

  // Surfaces
  static const Color surface = Color(0xFF2A1238); // Cards
  static const Color surfaceHigh = Color(0xFF3A1B4D); // Raised cards, inputs, sheets
  static const Color chocolate = Color(0xFF4A2519); // Chocolate-section accent surface
  static const Color waffleGold = Color(0xFFC98A2B); // Waffle-section accent

  // Accents
  static const Color primary = Color(0xFFFFD21F); // Main accent yellow
  static const Color primaryDark = Color(0xFFF2B600); // Gradient end for yellow buttons
  static const Color onPrimary = Color(0xFF2A0F3A); // Text/icons on yellow
  static const Color accentPurple = Color(0xFF7B2CBF); // Secondary accent, chips

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFBFA9CC);

  // Status
  static const Color success = Color(0xFF3DDC84); // Live dot, positive values
  static const Color danger = Color(0xFFFF5C7A); // Expenses, voids, errors
  static const Color hairline = Color(0x14FFFFFF); // White at 8%
  
  // Shadows & Glow
  static const Color cardShadow = Color(0x59000000); // Black at 35%
  static const Color buttonGlow = Color(0x4DFFD21F); // Primary yellow at 30%
}
