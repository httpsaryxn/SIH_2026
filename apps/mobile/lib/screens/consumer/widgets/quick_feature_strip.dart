import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class QuickFeatureStrip extends StatelessWidget {
  final Function(String feature) onFeatureTap;

  const QuickFeatureStrip({super.key, required this.onFeatureTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 720;

        final items = [
          _FeatureItem(
            title: 'Ingredients',
            subtitle: "Understand what's inside",
            icon: Icons.list_alt_rounded,
            iconBg: AppColors.tertiaryFixed,
            iconColor: AppColors.onTertiaryFixedVariant,
            featureKey: 'ingredients',
          ),
          _FeatureItem(
            title: 'Nutrition',
            subtitle: 'View facts & calories',
            icon: Icons.local_dining_rounded,
            iconBg: AppColors.primaryFixed.withValues(alpha: 0.3),
            iconColor: AppColors.primary,
            featureKey: 'nutrition',
          ),
          _FeatureItem(
            title: 'Label Check',
            subtitle: 'Identify anomalies',
            icon: Icons.verified_user_rounded,
            iconBg: AppColors.errorContainer,
            iconColor: AppColors.onErrorContainer,
            featureKey: 'label_check',
          ),
        ];

        if (isDesktop) {
          return Column(
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _buildTile(context, item),
                    ))
                .toList(),
          );
        }

        // Mobile horizontal scroll
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: items
                .map((item) => Container(
                      width: 220,
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      child: _buildTile(context, item),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildTile(BuildContext context, _FeatureItem item) {
    return InkWell(
      onTap: () => onFeatureTap(item.featureKey),
      borderRadius: AppSpacing.roundedMd,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(color: AppColors.surfaceVariant, width: 1),
          boxShadow: AppSpacing.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.iconBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(item.icon, color: item.iconColor, size: 20),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String featureKey;

  const _FeatureItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.featureKey,
  });
}
