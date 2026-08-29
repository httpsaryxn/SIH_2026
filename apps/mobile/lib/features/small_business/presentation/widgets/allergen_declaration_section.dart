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
          const Text(
            'Allergen Declaration',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select allergens present in your facility or product.',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 14),

          // Contains Label
          const Text(
            'Contains',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Chips Wrap
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
              // Add Chip Button
              Material(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onAddAllergenTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: AppColors.onSurfaceVariant,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
