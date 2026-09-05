import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class WeightServingCard extends StatelessWidget {
  const WeightServingCard({
    super.key,
    required this.netQuantityController,
    required this.servingSizeController,
    required this.netQuantityUnit,
    required this.servingSizeUnit,
    required this.onNetQuantityUnitChanged,
    required this.onServingSizeUnitChanged,
  });

  final TextEditingController netQuantityController;
  final TextEditingController servingSizeController;
  final String netQuantityUnit;
  final String servingSizeUnit;
  final ValueChanged<String?> onNetQuantityUnitChanged;
  final ValueChanged<String?> onServingSizeUnitChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
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
              // Header with Scale Icon
              Row(
                children: const [
                  Icon(
                    Icons.scale_rounded,
                    color: AppColors.brandDeepGreen,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Weight, Pricing & Serving',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Net Quantity Row
              Row(
                children: [
                  // Net Quantity Field
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Net Quantity *',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildInputField(
                          controller: netQuantityController,
                          placeholder: 'e.g. 250',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Net Quantity Unit Dropdown
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unit',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildUnitDropdown(
                          value: netQuantityUnit,
                          items: const ['g', 'kg', 'ml', 'L', 'pieces'],
                          onChanged: onNetQuantityUnitChanged,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Serving Size Row
              Row(
                children: [
                  // Serving Size Field
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Serving Size *',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildInputField(
                          controller: servingSizeController,
                          placeholder: 'e.g. 30',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Serving Size Unit Dropdown
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unit',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildUnitDropdown(
                          value: servingSizeUnit,
                          items: const ['g', 'ml', 'piece', 'tbsp', 'cup'],
                          onChanged: onServingSizeUnitChanged,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Helper Tip Note
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.secondarySlate,
                    size: 15,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Serving size determines the number of servings per pack automatically on your compliance label.',
                      style: TextStyle(
                        color: AppColors.secondarySlate,
                        fontSize: 11.5,
                        height: 1.3,
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String placeholder,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.outlineVariant,
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.onSurface,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(color: AppColors.outline, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildUnitDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 44,
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
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          icon: const Icon(
            Icons.expand_more_rounded,
            color: AppColors.onSurfaceVariant,
            size: 20,
          ),
          items: items.map((unit) {
            return DropdownMenuItem<String>(
              value: unit,
              child: Text(
                unit,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
