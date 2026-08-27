import 'package:flutter/material.dart';

/// AppSpacing encapsulates the spacing, radius, and elevation tokens from DESIGN.md.
abstract class AppSpacing {
  // Spacing Scale
  static const double base = 4.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double gutter = 16.0;
  static const double marginMobile = 20.0;
  static const double marginDesktop = 40.0;

  // Corner Radii
  static const double radiusSm = 4.0;
  static const double radiusDefault = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 9999.0;

  // BorderRadius helpers
  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedDefault = BorderRadius.all(Radius.circular(radiusDefault));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));

  // BoxShadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> cardHoverShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 25,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> primaryButtonShadow = [
    BoxShadow(
      color: Color(0x33006E2F),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> modalShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 25,
      offset: Offset(0, 10),
    ),
  ];
}
