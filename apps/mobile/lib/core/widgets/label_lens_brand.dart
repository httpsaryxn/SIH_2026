import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable brand widget for 'Label Lens'.
///
/// Follows the brand guidelines:
/// - Logo: [assets/images/labellens_logo.png]
/// - Text: 'Label' in black, 'Lens' in green.
class LabelLensBrand extends StatelessWidget {
  final double logoSize;
  final double fontSize;
  final bool showLogo;
  final bool isStacked;
  final Color? labelColor;
  final Color? lensColor;
  final String? tagline;
  final MainAxisAlignment mainAxisAlignment;

  const LabelLensBrand({
    super.key,
    this.logoSize = 28.0,
    this.fontSize = 20.0,
    this.showLogo = true,
    this.isStacked = false,
    this.labelColor,
    this.lensColor,
    this.tagline,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  /// Compact variation ideal for AppBars
  const LabelLensBrand.appBar({
    super.key,
    this.logoSize = 24.0,
    this.fontSize = 18.0,
    this.labelColor,
    this.lensColor,
  })  : showLogo = true,
        isStacked = false,
        tagline = null,
        mainAxisAlignment = MainAxisAlignment.start;

  /// Large centered variation for Auth / Onboarding / Splash
  const LabelLensBrand.hero({
    super.key,
    this.logoSize = 72.0,
    this.fontSize = 32.0,
    this.tagline,
    this.labelColor,
    this.lensColor,
  })  : showLogo = true,
        isStacked = true,
        mainAxisAlignment = MainAxisAlignment.center;

  @override
  Widget build(BuildContext context) {
    final effectiveLabelColor = labelColor ?? const Color(0xFF0F172A); // True rich black
    final effectiveLensColor = lensColor ?? const Color(0xFF059669); // Fresh vibrant brand green

    final logoWidget = showLogo
        ? ClipRRect(
            borderRadius: BorderRadius.circular(logoSize * 0.22),
            child: Image.asset(
              'assets/images/labellens_logo.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback graceful icon
                return Icon(
                  Icons.center_focus_strong_rounded,
                  size: logoSize,
                  color: effectiveLensColor,
                );
              },
            ),
          )
        : null;

    final textWidget = RichText(
      textAlign: isStacked ? TextAlign.center : TextAlign.start,
      text: TextSpan(
        style: GoogleFonts.plusJakartaSans(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          height: 1.15,
        ),
        children: [
          TextSpan(
            text: 'Label',
            style: TextStyle(color: effectiveLabelColor),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: 'Lens',
            style: TextStyle(color: effectiveLensColor),
          ),
        ],
      ),
    );

    if (isStacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (logoWidget != null) ...[
            logoWidget,
            SizedBox(height: fontSize * 0.4),
          ],
          textWidget,
          if (tagline != null && tagline!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              tagline!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: (fontSize * 0.45).clamp(11.0, 16.0),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (logoWidget != null) ...[
          logoWidget,
          SizedBox(width: logoSize * 0.35),
        ],
        textWidget,
      ],
    );
  }
}
