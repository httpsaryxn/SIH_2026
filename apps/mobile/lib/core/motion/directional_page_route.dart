import 'package:flutter/material.dart';
import 'app_curves.dart';
import 'app_durations.dart';

/// Standard drill-in forward-push / backward-pop page route for detail screens
/// (e.g. Complaint Detail, Violation Review, Multi-Capture).
///
/// Mimics iOS Cupertino drill-in and Android Material Shared Axis (X-axis) motion feel.
class DrillInPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  DrillInPageRoute({
    required this.page,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AppDurations.medium,
          reverseTransitionDuration: AppDurations.medium,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: AppCurves.entrance,
              reverseCurve: AppCurves.exit,
            );

            final secondaryCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: AppCurves.entrance,
              reverseCurve: AppCurves.exit,
            );

            // Incoming screen slides in from right to left
            final slideIn = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(curvedAnimation);

            // When another screen is pushed on top, slide slightly to the left (-0.25)
            final slideOutSecondary = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.25, 0.0),
            ).animate(secondaryCurved);

            return SlideTransition(
              position: slideOutSecondary,
              child: SlideTransition(
                position: slideIn,
                child: child,
              ),
            );
          },
        );
}

/// Direction enum for tab switches.
enum TabSlideDirection {
  forward,
  backward,
  none,
}

/// A direction-aware in-place animated switcher widget for tab bodies
/// in persistent shell architectures (e.g. [RegulatorShellScreen] and [ConsumerHomeScreen]).
///
/// Moving forward in tab index (e.g. 0 -> 3) slides incoming content from right-to-left.
/// Moving backward (e.g. 3 -> 1) slides incoming content from left-to-right.
/// Skipped tabs are never mounted or rendered.
class DirectionalTabSwitcher extends StatefulWidget {
  final int currentIndex;
  final Widget child;
  final Duration duration;
  final Curve curve;

  const DirectionalTabSwitcher({
    super.key,
    required this.currentIndex,
    required this.child,
    this.duration = AppDurations.medium,
    this.curve = AppCurves.entrance,
  });

  @override
  State<DirectionalTabSwitcher> createState() => _DirectionalTabSwitcherState();
}

class _DirectionalTabSwitcherState extends State<DirectionalTabSwitcher> {
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(covariant DirectionalTabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isForward = widget.currentIndex >= _previousIndex;

    return AnimatedSwitcher(
      duration: widget.duration,
      switchInCurve: widget.curve,
      switchOutCurve: AppCurves.exit,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topLeft,
          fit: StackFit.expand,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        // Distinguish the incoming widget from the outgoing widget by checking
        // if this transition matches the current child's key
        final isIncoming = child.key == widget.child.key;

        Offset inBeginOffset;
        Offset outEndOffset;

        if (isForward) {
          inBeginOffset = const Offset(0.35, 0.0);
          outEndOffset = const Offset(-0.35, 0.0);
        } else {
          inBeginOffset = const Offset(-0.35, 0.0);
          outEndOffset = const Offset(0.35, 0.0);
        }

        final slideTween = isIncoming
            ? Tween<Offset>(begin: inBeginOffset, end: Offset.zero)
            : Tween<Offset>(begin: Offset.zero, end: outEndOffset);

        return SlideTransition(
          position: slideTween.animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
