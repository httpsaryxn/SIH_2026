import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_curves.dart';
import 'app_durations.dart';

/// A subtle, non-intrusive entrance animation widget for list cards and content sections.
///
/// Provides a soft vertical slide (12dp) and fade-in, with an optional subtle index stagger
/// capped at a maximum of 5 items so long lists never feel sluggish.
class SlideFadeEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final double verticalOffset;
  final Duration duration;
  final Curve curve;

  const SlideFadeEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.verticalOffset = 12.0,
    this.duration = AppDurations.medium,
    this.curve = AppCurves.entrance,
  });

  @override
  State<SlideFadeEntrance> createState() => _SlideFadeEntranceState();
}

class _SlideFadeEntranceState extends State<SlideFadeEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.verticalOffset),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    // Stagger delay capped at max 5 items (~150ms max delay)
    final cappedIndex = math.min(widget.index, 5);
    final delay = AppDurations.staggerDelay * cappedIndex;

    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
