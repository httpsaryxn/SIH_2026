import 'package:flutter/material.dart';

/// AppColors encapsulates the design token colors from DESIGN.md (Fresh Slate palette).
abstract class AppColors {
  // Brand & Primary
  static const Color primary = Color(0xFF006E2F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF22C55E);
  static const Color onPrimaryContainer = Color(0xFF004B1E);
  static const Color primaryFixed = Color(0xFF6BFF8F);
  static const Color primaryFixedDim = Color(0xFF4AE176);
  static const Color onPrimaryFixed = Color(0xFF002109);
  static const Color onPrimaryFixedVariant = Color(0xFF005321);
  static const Color inversePrimary = Color(0xFF4AE176);

  // Secondary
  static const Color secondary = Color(0xFF565E74);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFDAE2FD);
  static const Color onSecondaryContainer = Color(0xFF5C647A);
  static const Color secondaryFixed = Color(0xFFDAE2FD);
  static const Color secondaryFixedDim = Color(0xFFBEC6E0);
  static const Color onSecondaryFixed = Color(0xFF131B2E);
  static const Color onSecondaryFixedVariant = Color(0xFF3F465C);

  // Tertiary
  static const Color tertiary = Color(0xFF005AC2);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF82ABFF);
  static const Color onTertiaryContainer = Color(0xFF003D88);
  static const Color tertiaryFixed = Color(0xFFD8E2FF);
  static const Color tertiaryFixedDim = Color(0xFFADC6FF);
  static const Color onTertiaryFixed = Color(0xFF001A42);
  static const Color onTertiaryFixedVariant = Color(0xFF004395);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF7F9FB);
  static const Color onBackground = Color(0xFF191C1E);
  static const Color surface = Color(0xFFF7F9FB);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF3D4A3D);
  static const Color surfaceDim = Color(0xFFD8DADC);
  static const Color surfaceBright = Color(0xFFF7F9FB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);
  static const Color surfaceVariant = Color(0xFFE0E3E5);
  static const Color inverseSurface = Color(0xFF2D3133);
  static const Color inverseOnSurface = Color(0xFFEFF1F3);
  static const Color surfaceTint = Color(0xFF006E2F);

  // Outlines & Borders
  static const Color outline = Color(0xFF6D7B6C);
  static const Color outlineVariant = Color(0xFFBCCBB9);
  static const Color borderSubtle = Color(0xFFE2E8F0);

  // Input background
  static const Color inputBackground = Color(0xFFF1F5F9);

  // Status & Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
}
