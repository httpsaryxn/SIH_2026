import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// A lightweight, robust Markdown renderer widget that formats
/// headers (##, ###), bold (**text**), italics (*text*), inline code (`code`),
/// bullet lists (- item), and status emojis (❌, ⚠️, ✅) without extra dependencies.
class MarkdownContentView extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;

  const MarkdownContentView({
    super.key,
    required this.text,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final defaultStyle = baseStyle ??
        GoogleFonts.plusJakartaSans(
          fontSize: 13,
          height: 1.5,
          color: AppColors.onSurface,
        );

    final lines = text.split('\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final rawLine = lines[i];
      final trimmed = rawLine.trim();

      if (trimmed.isEmpty) {
        // Subtle vertical space between paragraphs
        if (widgets.isNotEmpty && i < lines.length - 1) {
          widgets.add(const SizedBox(height: 6));
        }
        continue;
      }

      // ── Headers ──────────────────────────────────────────
      if (trimmed.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              trimmed.substring(4).trim(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              trimmed.substring(3).trim(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              trimmed.substring(2).trim(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
          ),
        );
      }
      // ── Bullet list items ────────────────────────────────
      else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        final content = trimmed.substring(2).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBulletPrefix(content),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: defaultStyle,
                      children: _parseInlineSpans(_stripLeadingEmoji(content), defaultStyle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // ── Standard Paragraph ───────────────────────────────
      else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: RichText(
              text: TextSpan(
                style: defaultStyle,
                children: _parseInlineSpans(trimmed, defaultStyle),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  /// Builds appropriate leading bullet or icon
  Widget _buildBulletPrefix(String content) {
    if (content.startsWith('❌')) {
      return const Padding(
        padding: EdgeInsets.only(top: 2),
        child: Icon(Icons.cancel_rounded, size: 15, color: Color(0xFFDC2626)),
      );
    } else if (content.startsWith('⚠️')) {
      return const Padding(
        padding: EdgeInsets.only(top: 2),
        child: Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFFD97706)),
      );
    } else if (content.startsWith('✅')) {
      return const Padding(
        padding: EdgeInsets.only(top: 2),
        child: Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF16A34A)),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 7),
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  /// Strips leading status emojis if we rendered them as icons
  String _stripLeadingEmoji(String content) {
    if (content.startsWith('❌') || content.startsWith('⚠️') || content.startsWith('✅')) {
      // Remove the emoji and following whitespace
      return content.substring(content.indexOf(' ') + 1).trim();
    }
    return content;
  }

  /// Parses inline markdown elements: **bold**, *italic*, and `code`
  List<InlineSpan> _parseInlineSpans(String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    final pattern = RegExp(r'(\*\*(.*?)\*\*|\*(.*?)\*|`(.*?)`)');
    int currentIndex = 0;

    for (final match in pattern.allMatches(text)) {
      // Add plain text before match
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: baseStyle,
        ));
      }

      final fullMatch = match.group(0)!;

      if (fullMatch.startsWith('**') && fullMatch.endsWith('**')) {
        // Bold
        spans.add(TextSpan(
          text: match.group(2) ?? '',
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ));
      } else if (fullMatch.startsWith('*') && fullMatch.endsWith('*')) {
        // Italic
        spans.add(TextSpan(
          text: match.group(3) ?? '',
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ));
      } else if (fullMatch.startsWith('`') && fullMatch.endsWith('`')) {
        // Inline code / chip
        final codeText = match.group(4) ?? '';
        final isViolationTag = codeText.contains('VIOLATION');
        final isPassTag = codeText.contains('COMPLIANT') || codeText.contains('PASS');
        final isWarnTag = codeText.contains('WARN');

        Color chipBg = const Color(0xFFF1F5F9);
        Color chipFg = const Color(0xFF334155);

        if (isViolationTag) {
          chipBg = const Color(0xFFFEE2E2);
          chipFg = const Color(0xFF991B1B);
        } else if (isPassTag) {
          chipBg = const Color(0xFFDCFCE7);
          chipFg = const Color(0xFF166534);
        } else if (isWarnTag) {
          chipBg = const Color(0xFFFEF3C7);
          chipFg = const Color(0xFF92400E);
        }

        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              codeText,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: chipFg,
              ),
            ),
          ),
        ));
      }

      currentIndex = match.end;
    }

    // Add remaining plain text
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: baseStyle,
      ));
    }

    return spans;
  }
}
