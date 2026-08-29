import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class IngredientItem {
  final String id;
  final String name;
  final double? percentage;

  const IngredientItem({required this.id, required this.name, this.percentage});
}

class IngredientsListSection extends StatelessWidget {
  const IngredientsListSection({
    super.key,
    required this.ingredients,
    required this.onAddIngredient,
    required this.onRemoveIngredient,
  });

  final List<IngredientItem> ingredients;
  final VoidCallback onAddIngredient;
  final ValueChanged<IngredientItem> onRemoveIngredient;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '🌿 INGREDIENTS',
                    style: TextStyle(
                      color: AppColors.brandDeepGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandDeepGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.brandDeepGreen.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${ingredients.length}',
                      style: const TextStyle(
                        color: AppColors.brandDeepGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              // Circular Add Button
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onAddIngredient,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.brandFreshGreen,
                          AppColors.brandDeepGreen,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandFreshGreen.withValues(
                            alpha: 0.35,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Body: Empty State or Ingredient Items List
        if (ingredients.isEmpty)
          _buildEmptyState()
        else
          _buildIngredientsList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandDeepGreen.withValues(alpha: 0.3),
          width: 1.2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.list_alt_rounded,
              color: AppColors.brandDeepGreen,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No ingredients added',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Search or add your first ingredient to start building the list.',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onAddIngredient,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandDeepGreen,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add, size: 18),
                SizedBox(width: 6),
                Text(
                  'Add Ingredient',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: ingredients.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
        itemBuilder: (context, index) {
          final item = ingredients[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Order number badge
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.brandDeepGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.brandDeepGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (item.percentage != null)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.percentage!.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 18,
                  ),
                  onPressed: () => onRemoveIngredient(item),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
