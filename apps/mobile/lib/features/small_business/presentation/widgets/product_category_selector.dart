import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProductCategorySelector extends StatelessWidget {
  const ProductCategorySelector({
    super.key,
    this.selectedCategory,
    this.onCategoryChanged,
    this.onHelpTap,
    this.categories = const [
      'Pickles & Condiments',
      'Spices & Seasonings',
      'Honey & Natural Sweeteners',
      'Dairy & Ghee Products',
      'Edible Oils & Cold Pressed Oils',
      'Snacks & Namkeen',
      'Sweets & Mithai',
      'Grains, Flours & Pulses',
      'Sauces, Chutneys & Pastes',
      'Beverages & Tea/Coffee',
      'Bakery & Confectionery',
      'Organic & Health Foods',
      'Ready-to-Eat / Ready-to-Cook',
      'Other Packaged Foods',
    ],
  });

  final String? selectedCategory;
  final ValueChanged<String?>? onCategoryChanged;
  final VoidCallback? onHelpTap;
  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    // Ensure selectedCategory is guaranteed to be in the items list to prevent DropdownButton assertion errors
    final effectiveCategories = List<String>.from(categories);
    if (selectedCategory != null &&
        selectedCategory!.isNotEmpty &&
        !effectiveCategories.contains(selectedCategory)) {
      effectiveCategories.insert(0, selectedCategory!);
    }

    final effectiveValue =
        (selectedCategory != null &&
                selectedCategory!.isNotEmpty &&
                effectiveCategories.contains(selectedCategory))
            ? selectedCategory
            : null;

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
          // Header with Required badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Product Category *',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandDeepGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'FSSAI MANDATORY',
                  style: TextStyle(
                    color: AppColors.brandDeepGreen,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
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
                value: effectiveValue,
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
                      'Select product category',
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
                items:
                    effectiveCategories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.category_outlined,
                              color: AppColors.brandDeepGreen,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                cat,
                                style: const TextStyle(
                                  color: AppColors.onSurface,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
