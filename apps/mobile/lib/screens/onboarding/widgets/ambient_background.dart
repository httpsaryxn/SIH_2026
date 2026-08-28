import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// AmbientBackground renders a subtle decorative radial glow at the top.
class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: AppColors.background,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 380,
          child: IgnorePointer(
            child: CustomPaint(
              painter: _AmbientGlowPainter(),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _AmbientGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -1),
        radius: 0.9,
        colors: [
          AppColors.primaryContainer.withValues(alpha: 0.15),
          AppColors.primaryContainer.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
