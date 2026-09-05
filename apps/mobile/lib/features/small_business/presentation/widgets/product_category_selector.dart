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
            color: Colors.black.withValues(alpha: 0.025),
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
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Flexible(
                      child: Text(
                        'Product Category',
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '*',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandDeepGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.brandDeepGreen.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.verified_outlined,
                      size: 11,
                      color: AppColors.brandDeepGreen,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'FSSAI MANDATORY',
                      style: TextStyle(
                        color: AppColors.brandDeepGreen,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Dropdown Input Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: effectiveValue,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(14),
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
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 22,
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
                                  fontSize: 14,
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
          InkWell(
            onTap: onHelpTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.help_outline_rounded,
                    size: 14,
                    color: AppColors.brandBlue,
                  ),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Need help finding your category?',
                      style: TextStyle(
                        color: AppColors.brandBlue,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
