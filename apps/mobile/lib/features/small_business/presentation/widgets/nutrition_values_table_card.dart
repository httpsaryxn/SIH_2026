import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class NutrientRowData {
  final String label;
  final IconData? icon;
  final bool isRequired;
  final bool isSubNutrient;
  final String unit;
  final TextEditingController controller;

  NutrientRowData({
    required this.label,
    this.icon,
    this.isRequired = false,
    this.isSubNutrient = false,
    required this.unit,
    required this.controller,
  });
}

class NutritionValuesTableCard extends StatelessWidget {
  const NutritionValuesTableCard({
    super.key,
    required this.nutrients,
    required this.selectedAdditionalNutrient,
    required this.availableAdditionalNutrients,
    required this.onAdditionalNutrientChanged,
    required this.onAddNutrientTap,
  });

  final List<NutrientRowData> nutrients;
  final String? selectedAdditionalNutrient;
  final List<String> availableAdditionalNutrients;
  final ValueChanged<String?> onAdditionalNutrientChanged;
  final VoidCallback onAddNutrientTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.brandDeepGreen.withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandDeepGreen.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header with Science/Lab Icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.brandDeepGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.science_outlined,
                      color: AppColors.brandDeepGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Nutrition Values Table',
                          style: TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Enter values per 100 g from your lab report or supplier CoA',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nutrient Rows
              ...nutrients.map((item) => _buildNutrientRow(item)),

              const SizedBox(height: 16),

              // Add Additional Nutrient Row
              const Text(
                'Add Additional Micronutrient',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedAdditionalNutrient,
                          hint: const Text(
                            'Select additional nutrient...',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          isExpanded: true,
                          icon: const Icon(
                            Icons.expand_more_rounded,
                            color: AppColors.onSurfaceVariant,
                            size: 20,
                          ),
                          items: availableAdditionalNutrients.map((nutr) {
                            return DropdownMenuItem<String>(
                              value: nutr,
                              child: Text(
                                nutr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: onAdditionalNutrientChanged,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: onAddNutrientTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandDeepGreen,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientRow(NutrientRowData item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          // Left icon / indent
          if (item.isSubNutrient)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.onSurfaceVariant,
                  shape: BoxShape.circle,
                ),
              ),
            )
          else if (item.icon != null) ...[
            Icon(item.icon, size: 16, color: AppColors.brandDeepGreen),
            const SizedBox(width: 8),
          ] else
            const SizedBox(width: 24),

          // Label
          Expanded(
            child: Text(
              item.isRequired ? '${item.label} *' : item.label,
              style: TextStyle(
                fontSize: item.isSubNutrient ? 13 : 13.5,
                fontWeight: item.isSubNutrient
                    ? FontWeight.w400
                    : FontWeight.w700,
                color: item.isSubNutrient
                    ? AppColors.onSurfaceVariant
                    : AppColors.onSurface,
              ),
            ),
          ),

          // Input field and unit
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.outlineVariant,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: item.controller,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                child: Text(
                  item.unit,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
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
