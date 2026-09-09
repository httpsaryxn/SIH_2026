import 'package:flutter/animation.dart';

/// Standard easing curves matching native iOS and Android Material motion feel.
///
/// Linear curves are strictly prohibited anywhere motion is added.
abstract final class AppCurves {
  /// Natural decelerating curve for incoming elements and screen entrances.
  /// Matches native platform feel (fast start, gradual settle).
  static const Curve entrance = Curves.easeOutCubic;

  /// Natural accelerating curve for outgoing elements and screen dismissals.
  static const Curve exit = Curves.easeInCubic;

  /// Tactile spring-like curve for button releases and card rebounds.
  static const Curve spring = Curves.easeOutBack;

  /// Balanced bidirectional easing curve for symmetric state transitions and toggles.
  static const Curve standard = Curves.easeInOutCubic;

  /// Emphasized deceleration for prominent cards, dialogs, and sheets.
  static const Curve emphasized = Curves.easeOutQuart;
}
