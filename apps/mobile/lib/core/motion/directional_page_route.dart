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

    return ClipRect(
      child: AnimatedSwitcher(
        duration: widget.duration,
        switchInCurve: widget.curve,
        switchOutCurve: AppCurves.exit,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
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
      ),
    );
  }
}

/// A state-preserving direction-aware tab container.
///
/// Keeps all [children] alive in memory (preserving scroll positions, text field inputs,
/// and in-progress form/capture data) while animating visible tab index changes with
/// direction-aware horizontal sliding matching iOS and Android native feel.
class DirectionalIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;
  final Curve curve;

  const DirectionalIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = AppDurations.medium,
    this.curve = AppCurves.entrance,
  });

  @override
  State<DirectionalIndexedStack> createState() =>
      _DirectionalIndexedStackState();
}

class _DirectionalIndexedStackState extends State<DirectionalIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int _currentIndex = 0;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _previousIndex = widget.index;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
      reverseCurve: AppCurves.exit,
    );
  }

  @override
  void didUpdateWidget(covariant DirectionalIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _previousIndex = _currentIndex;
      _currentIndex = widget.index;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isForward = _currentIndex >= _previousIndex;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        return AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            final progress = _animation.value;
            final isStillAnimating = _controller.isAnimating;

            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: List.generate(widget.children.length, (i) {
                  final isCurrent = i == _currentIndex;
                  final isPrevious = i == _previousIndex;

                  final childWithBounds = OverflowBox(
                    minWidth: constraints.maxWidth,
                    maxWidth: constraints.maxWidth,
                    minHeight: constraints.maxHeight,
                    maxHeight: constraints.maxHeight,
                    child: widget.children[i],
                  );

                  bool isVisible = isCurrent;
                  Offset offset = Offset.zero;
                  double opacity = 1.0;

                  if (isStillAnimating && _previousIndex != _currentIndex) {
                    if (isPrevious) {
                      isVisible = true;
                      final outFraction = isForward ? -0.35 : 0.35;
                      offset = Offset(outFraction * progress * screenWidth, 0.0);
                      opacity = (1.0 - progress).clamp(0.0, 1.0);
                    } else if (isCurrent) {
                      isVisible = true;
                      final inFraction = isForward ? 0.35 : -0.35;
                      offset =
                          Offset(inFraction * (1.0 - progress) * screenWidth, 0.0);
                      opacity = progress.clamp(0.0, 1.0);
                    }
                  }

                  return KeyedSubtree(
                    key: ValueKey<int>(i),
                    child: TickerMode(
                      enabled: isVisible,
                      child: Offstage(
                        offstage: !isVisible,
                        child: Transform.translate(
                          offset: offset,
                          child: Opacity(
                            opacity: opacity,
                            child: childWithBounds,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }
}

