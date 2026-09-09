import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_curves.dart';
import 'app_durations.dart';

/// A reusable physically-based wrapper providing a native-feeling scale-down-on-press
/// micro-interaction on buttons, cards, and list items.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool enableHapticFeedback;
  final HitTestBehavior behavior;

  const Pressable({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.enableHapticFeedback = true,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppCurves.standard,
        reverseCurve: AppCurves.spring,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant Pressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pressedScale != widget.pressedScale) {
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: widget.pressedScale,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: AppCurves.standard,
          reverseCurve: AppCurves.spring,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed == null && widget.onLongPress == null) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onPressed == null && widget.onLongPress == null) return;
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _onTap() {
    if (widget.onPressed == null) return;
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed != null ? _onTap : null,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
