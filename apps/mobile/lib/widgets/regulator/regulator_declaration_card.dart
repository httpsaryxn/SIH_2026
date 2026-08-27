import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/regulator_violation.dart';

class RegulatorDeclarationCard extends StatelessWidget {
  final RegulatorDeclaration declaration;

  const RegulatorDeclarationCard({
    super.key,
    required this.declaration,
  });

  @override
  Widget build(BuildContext context) {
    final isViolation = declaration.isViolation;
    final isCompliant = declaration.isCompliant;

    Color borderColor = isViolation
        ? AppColors.error.withValues(alpha: 0.35)
        : AppColors.outlineVariant.withValues(alpha: 0.35);

    Color iconColor = isViolation ? AppColors.error : AppColors.primary;
    IconData icon = isViolation
        ? Icons.cancel_rounded
        : (isCompliant ? Icons.check_circle_rounded : Icons.info_outline_rounded);

    Color badgeBg = isViolation
        ? AppColors.error
        : (isCompliant
            ? AppColors.primaryContainer.withValues(alpha: 0.25)
            : const Color(0xFFFEF3C7));

    Color badgeText = isViolation
        ? AppColors.onError
        : (isCompliant ? AppColors.onPrimaryContainer : const Color(0xFF92400E));

    Color confidenceColor = isViolation ? AppColors.error : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borderColor),
        boxShadow: AppSpacing.cardShadow,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  declaration.fieldName.toUpperCase(),
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontSize: 13,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  declaration.status,
                  style: AppTypography.labelSm.copyWith(
                    color: badgeText,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Two-column metrics
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Extracted Value',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      declaration.extractedValue,
                      style: AppTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OCR Confidence',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${declaration.confidencePercent}%',
                      style: AppTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: confidenceColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Rule Cite box if present
          if (declaration.ruleCitation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm + 4),
              decoration: BoxDecoration(
                color: isViolation
                    ? AppColors.errorContainer.withValues(alpha: 0.3)
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                border: Border.all(
                  color: isViolation
                      ? AppColors.errorContainer
                      : AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: RichText(
                text: TextSpan(
                  style: AppTypography.bodySm.copyWith(
                    color: isViolation
                        ? AppColors.onErrorContainer
                        : AppColors.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Rule Cite: ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text:
                          '${declaration.ruleCitation} – ${declaration.ruleDescription}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
