import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum ClaimCategory {
  common('Common', Icons.stars_rounded),
  dietary('Dietary & Lifestyle', Icons.spa_rounded),
  nutritional('Nutritional & Health', Icons.favorite_rounded),
  quality('Quality & Origin', Icons.verified_user_rounded);

  const ClaimCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

class ProductClaim {
  final String id;
  final String title;
  final String description;
  final ClaimCategory category;
  final bool requiresLabReport;
  final String? legalReference;

  const ProductClaim({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.requiresLabReport = false,
    this.legalReference,
  });
}

class ClaimItemCard extends StatelessWidget {
  const ClaimItemCard({
    super.key,
    required this.claim,
    required this.isSelected,
    required this.onTap,
  });

  final ProductClaim claim;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandDeepGreen.withValues(alpha: 0.06)
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandDeepGreen
                  : AppColors.outlineVariant.withValues(alpha: 0.4),
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.brandDeepGreen.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.015),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Custom checkbox / radio indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandDeepGreen
                      : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandDeepGreen
                        : AppColors.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            claim.title,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.brandDeepGreen
                                  : AppColors.onSurface,
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (claim.requiresLabReport) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Lab Proof',
                              style: TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      claim.description,
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.85),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Selection badge / indicator
              if (isSelected) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandDeepGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Added',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
