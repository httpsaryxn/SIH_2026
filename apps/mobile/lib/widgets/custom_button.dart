import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';

enum ButtonVariant { primary, secondary, outline, ghost }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final ButtonVariant variant;
  final Widget? icon;
  final double height;
  final BorderRadius? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.height = 52,
    this.borderRadius,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  Color _getBackgroundColor() {
    if (!_isEnabled && widget.variant == ButtonVariant.primary) {
      return AppColors.primary.withValues(alpha: 0.45);
    }
    switch (widget.variant) {
      case ButtonVariant.primary:
        return AppColors.primary;
      case ButtonVariant.secondary:
        return AppColors.secondaryContainer;
      case ButtonVariant.outline:
      case ButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    if (!_isEnabled) {
      return AppColors.onPrimary.withValues(alpha: 0.7);
    }
    switch (widget.variant) {
      case ButtonVariant.primary:
        return AppColors.onPrimary;
      case ButtonVariant.secondary:
        return AppColors.onSecondaryContainer;
      case ButtonVariant.outline:
        return AppColors.onSurface;
      case ButtonVariant.ghost:
        return AppColors.tertiary;
    }
  }

  Border? _getBorder() {
    if (widget.variant == ButtonVariant.outline) {
      return Border.all(
        color: _isEnabled ? AppColors.outlineVariant : AppColors.outlineVariant.withValues(alpha: 0.5),
        width: 1,
      );
    }
    return null;
  }

  List<BoxShadow> _getBoxShadow() {
    if (_isEnabled && widget.variant == ButtonVariant.primary) {
      return AppSpacing.primaryButtonShadow;
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? AppSpacing.roundedFull;

    Widget buttonContent = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: effectiveRadius,
        border: _getBorder(),
        boxShadow: _getBoxShadow(),
      ),
      child: Center(
        child: widget.isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    widget.icon!,
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    widget.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getTextColor(),
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
      ),
    );

    if (widget.isFullWidth) {
      buttonContent = SizedBox(width: double.infinity, child: buttonContent);
    }

    return AnimatedScale(
      scale: _isPressed && _isEnabled ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: effectiveRadius,
          onTapDown: (_) {
            if (_isEnabled) setState(() => _isPressed = true);
          },
          onTapUp: (_) {
            if (_isEnabled) setState(() => _isPressed = false);
          },
          onTapCancel: () {
            if (_isEnabled) setState(() => _isPressed = false);
          },
          onTap: _isEnabled ? widget.onPressed : null,
          child: buttonContent,
        ),
      ),
    );
  }
}
