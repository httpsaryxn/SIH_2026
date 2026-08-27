import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/regulator_company.dart';

class RegulatorTimelineTile extends StatelessWidget {
  final RegulatorTimelineEvent event;
  final bool isFirst;
  final bool isLast;

  const RegulatorTimelineTile({
    super.key,
    required this.event,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    Color dotBg;
    Color dotIconColor;
    IconData dotIcon;

    if (event.isViolation) {
      dotBg = AppColors.errorContainer;
      dotIconColor = AppColors.error;
      dotIcon = Icons.warning_amber_rounded;
    } else if (event.isAuditPassed) {
      dotBg = AppColors.primaryContainer.withValues(alpha: 0.35);
      dotIconColor = AppColors.primary;
      dotIcon = Icons.check_circle_outline_rounded;
    } else if (event.isNoticeIssued) {
      dotBg = AppColors.tertiaryContainer.withValues(alpha: 0.35);
      dotIconColor = AppColors.tertiary;
      dotIcon = Icons.description_outlined;
    } else {
      dotBg = AppColors.secondaryContainer;
      dotIconColor = AppColors.secondary;
      dotIcon = Icons.fact_check_outlined;
    }

    final formattedDate = DateFormat('MMM dd, yyyy').format(event.date);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Line & Dot Column
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: dotBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceContainerLowest,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      dotIcon,
                      size: 13,
                      color: dotIconColor,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.surfaceVariant,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          // Content Column
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppSpacing.md + 4,
                top: 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.title,
                    style: AppTypography.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.description,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  if (event.officerName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${event.officerName}${event.batchNo.isNotEmpty ? ' • ${event.batchNo}' : ''}',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
