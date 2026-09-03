import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AllergenDeclarationSection extends StatelessWidget {
  const AllergenDeclarationSection({
    super.key,
    required this.selectedAllergens,
    required this.onRemoveAllergen,
    required this.onAddAllergenTap,
  });

  final List<String> selectedAllergens;
  final ValueChanged<String> onRemoveAllergen;
  final VoidCallback onAddAllergenTap;

  static const Color tertiaryAllergenColor = Color(0xFF80253D);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Text(
            'FOOD SAFETY',
            style: TextStyle(
              color: tertiaryAllergenColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Allergen Declaration',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onAddAllergenTap,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: const [
                      Icon(Icons.add_rounded, size: 14, color: tertiaryAllergenColor),
                      SizedBox(width: 2),
                      Text(
                        'Add Allergen',
                        style: TextStyle(
                          color: tertiaryAllergenColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Select allergens present in your formulation or handled on the same line.',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12.5),
          ),
          const SizedBox(height: 12),

          // Contains Section
          if (selectedAllergens.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: tertiaryAllergenColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tertiaryAllergenColor.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: tertiaryAllergenColor,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'No mandatory allergens declared yet.',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onAddAllergenTap,
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: tertiaryAllergenColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 0),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...selectedAllergens.map((allergen) {
                  return Container(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 6,
                      top: 6,
                      bottom: 6,
                    ),
                    decoration: BoxDecoration(
                      color: tertiaryAllergenColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: tertiaryAllergenColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          allergen,
                          style: const TextStyle(
                            color: tertiaryAllergenColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => onRemoveAllergen(allergen),
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: tertiaryAllergenColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}
