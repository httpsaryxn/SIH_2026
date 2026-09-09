/// Standard animation durations used systematically across the entire app.
///
/// Magic numbers (e.g. `Duration(milliseconds: 237)`) must never be used inline.
/// Motion tuning is controlled globally through this class.
abstract final class AppDurations {
  /// Ultra-fast duration for micro-interactions, icon state flips, and quick haptics.
  static const Duration micro = Duration(milliseconds: 80);

  /// Fast duration for button presses, touch-down responses, toggle switches, and small state changes.
  static const Duration fast = Duration(milliseconds: 140);

  /// Medium duration for page transitions, direction-aware tab switches, and bottom sheet presentations.
  static const Duration medium = Duration(milliseconds: 260);

  /// Slow duration for modal dialog reveals, hero transitions, and expand/collapse layout morphs.
  static const Duration slow = Duration(milliseconds: 380);

  /// Extra-slow duration for subtle ambient loops and background shifts.
  static const Duration ambient = Duration(milliseconds: 1200);

  /// Stagger delay between successive list items during list entrance animations.
  static const Duration staggerDelay = Duration(milliseconds: 30);
}
