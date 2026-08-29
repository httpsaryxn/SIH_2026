import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProductCategorySelector extends StatelessWidget {
  const ProductCategorySelector({
    super.key,
    this.selectedCategory,
    this.onCategoryChanged,
    this.onHelpTap,
    this.categories = const [
      'Spices & Condiments',
      'Beverages',
      'Snacks & Sweets',
      'Grains & Pulses',
      'Sauces & Condiments',
      'Bakery & Confectionery',
      'Other Food Products',
    ],
  });

  final String? selectedCategory;
  final ValueChanged<String?>? onCategoryChanged;
  final VoidCallback? onHelpTap;
  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Optional badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Product Category',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'OPTIONAL',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Dropdown Input Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outlineVariant, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                hint: Row(
                  children: const [
                    Icon(
                      Icons.category_outlined,
                      color: AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Select a category',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                icon: const Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.onSurfaceVariant,
                ),
                onChanged: onCategoryChanged,
                items: categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.category_outlined,
                          color: AppColors.brandDeepGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          cat,
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Need help link
          GestureDetector(
            onTap: onHelpTap,
            child: const Text(
              'Need help finding your category?',
              style: TextStyle(
                color: AppColors.brandBlue,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
