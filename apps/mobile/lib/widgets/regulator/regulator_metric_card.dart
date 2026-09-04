import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

class RegulatorMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? deltaText;
  final Color? deltaColor;
  final bool isFullWidth;
  final VoidCallback? onTap;

  const RegulatorMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.tertiary,
    this.deltaText,
    this.deltaColor,
    this.isFullWidth = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.surfaceVariant),
          boxShadow: AppSpacing.cardShadow,
        ),
        child: isFullWidth ? _buildFullWidthLayout() : _buildStandardLayout(),
      ),
    );
  }

  Widget _buildStandardLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              icon,
              size: 22,
              color: iconColor,
            ),
            if (deltaText != null)
              Text(
                deltaText!,
                style: AppTypography.labelSm.copyWith(
                  color: deltaColor ?? AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: AppTypography.headlineMd.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title.toUpperCase(),
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.5,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildFullWidthLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTypography.headlineMd.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title.toUpperCase(),
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
                letterSpacing: 0.5,
                fontSize: 11,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: AppColors.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.onErrorContainer,
          ),
        ),
      ],
    );
  }
}
