import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

enum RegulatorBadgeType {
  compliant,
  violation,
  warning,
  highRisk,
  info,
  neutral,
  gavelConfidence,
}

class RegulatorStatusBadge extends StatelessWidget {
  final String label;
  final RegulatorBadgeType type;
  final IconData? icon;
  final bool filled;
  final EdgeInsetsGeometry? padding;

  const RegulatorStatusBadge({
    super.key,
    required this.label,
    this.type = RegulatorBadgeType.neutral,
    this.icon,
    this.filled = false,
    this.padding,
  });

  factory RegulatorStatusBadge.fromStatus(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('compliant') || lower.contains('passed')) {
      return RegulatorStatusBadge(
        label: status,
        type: RegulatorBadgeType.compliant,
      );
    } else if (lower.contains('violation') ||
        lower.contains('high') ||
        lower.contains('action')) {
      return RegulatorStatusBadge(
        label: status,
        type: RegulatorBadgeType.violation,
      );
    } else if (lower.contains('warning') ||
        lower.contains('allergen') ||
        lower.contains('medium')) {
      return RegulatorStatusBadge(
        label: status,
        type: RegulatorBadgeType.warning,
      );
    } else if (lower.contains('draft') ||
        lower.contains('review') ||
        lower.contains('weight')) {
      return RegulatorStatusBadge(
        label: status,
        type: RegulatorBadgeType.info,
      );
    }
    return RegulatorStatusBadge(
      label: status,
      type: RegulatorBadgeType.neutral,
    );
  }

  factory RegulatorStatusBadge.gavelConfidence(int confidence) {
    final isHigh = confidence >= 85;
    return RegulatorStatusBadge(
      label: '$confidence%',
      type: isHigh
          ? RegulatorBadgeType.gavelConfidence
          : RegulatorBadgeType.neutral,
      icon: Icons.gavel_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (type) {
      case RegulatorBadgeType.compliant:
        bgColor = AppColors.primaryContainer.withValues(alpha: 0.25);
        textColor = AppColors.onPrimaryContainer;
        break;
      case RegulatorBadgeType.violation:
        if (filled) {
          bgColor = AppColors.error;
          textColor = AppColors.onError;
        } else {
          bgColor = AppColors.errorContainer;
          textColor = AppColors.onErrorContainer;
        }
        break;
      case RegulatorBadgeType.warning:
        bgColor = const Color(0xFFFEF3C7); // amber-100
        textColor = const Color(0xFF92400E); // amber-800
        break;
      case RegulatorBadgeType.highRisk:
        bgColor = AppColors.errorContainer;
        textColor = AppColors.onErrorContainer;
        break;
      case RegulatorBadgeType.info:
        bgColor = AppColors.tertiaryContainer.withValues(alpha: 0.35);
        textColor = AppColors.onTertiaryContainer;
        break;
      case RegulatorBadgeType.gavelConfidence:
        bgColor = AppColors.errorContainer;
        textColor = AppColors.onErrorContainer;
        break;
      case RegulatorBadgeType.neutral:
        bgColor = AppColors.surfaceContainerHigh;
        textColor = AppColors.onSurfaceVariant;
        break;
    }

    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4.0,
          ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
