import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum NutritionValuesDisplayMode { per100g, perServing, both }

enum NutritionLabelFormat { table, text }

class NutritionFormatSettingsCard extends StatelessWidget {
  const NutritionFormatSettingsCard({
    super.key,
    required this.displayMode,
    required this.labelFormat,
    required this.targetAudience,
    required this.ageGroup,
    required this.onDisplayModeChanged,
    required this.onLabelFormatChanged,
    required this.onTargetAudienceChanged,
    required this.onAgeGroupChanged,
  });

  final NutritionValuesDisplayMode displayMode;
  final NutritionLabelFormat labelFormat;
  final String targetAudience;
  final String ageGroup;
  final ValueChanged<NutritionValuesDisplayMode> onDisplayModeChanged;
  final ValueChanged<NutritionLabelFormat> onLabelFormatChanged;
  final ValueChanged<String?> onTargetAudienceChanged;
  final ValueChanged<String?> onAgeGroupChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Show Nutrition Values As
          const Text(
            'Show Nutrition Values As',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFECEEF0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildSegmentButton(
                  title: 'Per 100g/ml',
                  isSelected: displayMode == NutritionValuesDisplayMode.per100g,
                  onTap: () =>
                      onDisplayModeChanged(NutritionValuesDisplayMode.per100g),
                ),
                _buildSegmentButton(
                  title: 'Per Serving',
                  isSelected:
                      displayMode == NutritionValuesDisplayMode.perServing,
                  onTap: () => onDisplayModeChanged(
                    NutritionValuesDisplayMode.perServing,
                  ),
                ),
                _buildSegmentButton(
                  title: 'Both',
                  isSelected: displayMode == NutritionValuesDisplayMode.both,
                  onTap: () =>
                      onDisplayModeChanged(NutritionValuesDisplayMode.both),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Nutrition Label Format
          const Text(
            'Nutrition Label Format',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFECEEF0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildSegmentButton(
                  title: 'Table',
                  isSelected: labelFormat == NutritionLabelFormat.table,
                  onTap: () => onLabelFormatChanged(NutritionLabelFormat.table),
                ),
                _buildSegmentButton(
                  title: 'Text',
                  isSelected: labelFormat == NutritionLabelFormat.text,
                  onTap: () => onLabelFormatChanged(NutritionLabelFormat.text),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Target Audience & Age Group
          const Text(
            'Target Audience & Age Group',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Target Audience Dropdown
              Expanded(
                child: _buildDropdown(
                  value: targetAudience,
                  items: const [
                    'General',
                    'Children',
                    'Pregnant Women',
                    'Athletes',
                  ],
                  onChanged: onTargetAudienceChanged,
                ),
              ),
              const SizedBox(width: 10),
              // Age Group Dropdown
              Expanded(
                child: _buildDropdown(
                  value: ageGroup,
                  items: const [
                    'Adults (18+)',
                    'Teens (13-17)',
                    'Kids (4-12)',
                    'Infants (0-3)',
                    'All Ages',
                  ],
                  onChanged: onAgeGroupChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.brandDeepGreen
                  : AppColors.secondarySlate,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.8),
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
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 12.5,
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
