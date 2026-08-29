import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'claim_item_card.dart';

class ClaimsCategoryTabBar extends StatelessWidget {
  const ClaimsCategoryTabBar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final ClaimCategory? selectedCategory;
  final ValueChanged<ClaimCategory?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // "All" Chip
          _CategoryChip(
            label: 'All Claims',
            icon: Icons.grid_view_rounded,
            isSelected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          const SizedBox(width: 8),

          // Dynamic Category Chips
          ...ClaimCategory.values.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _CategoryChip(
                label: cat.label,
                icon: cat.icon,
                isSelected: selectedCategory == cat,
                onTap: () => onCategorySelected(cat),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandDeepGreen
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandDeepGreen
                  : AppColors.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.brandDeepGreen.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.onSurface,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
