import 'package:flutter/material.dart';

/// A button wrapper that ensures buttons in forms and sticky bars respond
/// immediately on a single tap, even when the software keyboard is open.
///
/// When the keyboard is active, tapping a button normally triggers keyboard dismissal,
/// which causes the layout to shift and cancels Flutter's standard `TapGestureRecognizer`.
/// This widget captures `PointerDown` directly before any layout shift occurs, dismisses
/// the keyboard cleanly, debounces accidental double-taps, and invokes the callback once.
class SingleTapButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget Function(BuildContext context, VoidCallback? onPressed) builder;
  final int debounceMs;

  const SingleTapButton({
    super.key,
    required this.onPressed,
    required this.builder,
    this.debounceMs = 700,
  });

  @override
  State<SingleTapButton> createState() => _SingleTapButtonState();
}

class _SingleTapButtonState extends State<SingleTapButton> {
  int _lastTapTimestamp = 0;

  void _trigger() {
    if (widget.onPressed == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTapTimestamp < widget.debounceMs) {
      return;
    }
    _lastTapTimestamp = now;

    // Unfocus any active text field so the keyboard dismisses cleanly
    FocusManager.instance.primaryFocus?.unfocus();

    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onPressed == null) {
      return widget.builder(context, null);
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _trigger(),
      child: widget.builder(context, _trigger),
    );
  }
}
