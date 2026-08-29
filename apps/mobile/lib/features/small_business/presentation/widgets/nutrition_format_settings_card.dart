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

  static const List<String> targetAudienceOptions = [
    'General Population (All Consumers)',
    'Fitness & High Protein / Athletes',
    'Diabetic & Low Glycemic Index',
    'Weight Management & Keto',
    'Vegan & 100% Plant-Based',
    'Gluten-Free & Celiac Safe',
    'Heart Health & Low Sodium',
    'Immunity & Wellness',
    'Senior & Geriatric Care',
    'Maternal & Lactating Mothers',
    'Kids & Growing Children',
  ];

  static const List<String> ageGroupOptions = [
    'All Age Groups (General)',
    'Infants (0-6 months)',
    'Infants (6-24 months)',
    'Toddlers (1-3 years)',
    'Children (4-8 years)',
    'Pre-Teens (9-12 years)',
    'Adolescents / Teens (13-17 years)',
    'Young Adults (18-35 years)',
    'Middle-Aged Adults (36-59 years)',
    'Senior Citizens (60+ years)',
  ];

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
          Row(
            children: [
              _buildFormatOption(
                title: 'Tabular Format',
                subtitle: 'FSSAI Standard Grid',
                icon: Icons.table_chart_rounded,
                isSelected: labelFormat == NutritionLabelFormat.table,
                onTap: () => onLabelFormatChanged(NutritionLabelFormat.table),
              ),
              const SizedBox(width: 10),
              _buildFormatOption(
                title: 'Linear / Text',
                subtitle: 'Continuous for small packs',
                icon: Icons.view_headline_rounded,
                isSelected: labelFormat == NutritionLabelFormat.text,
                onTap: () => onLabelFormatChanged(NutritionLabelFormat.text),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Target Audience & Age Group
          const Text(
            'Target Audience & Consumer Age Group',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              // Target Audience Dropdown
              _buildDropdown(
                label: 'Target Demographic',
                value: targetAudience,
                items: targetAudienceOptions,
                onChanged: onTargetAudienceChanged,
              ),
              const SizedBox(height: 10),
              // Age Group Dropdown
              _buildDropdown(
                label: 'Consumer Age Group',
                value: ageGroup,
                items: ageGroupOptions,
                onChanged: onAgeGroupChanged,
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

  Widget _buildFormatOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandDeepGreen.withValues(alpha: 0.06)
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandDeepGreen
                  : AppColors.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppColors.brandDeepGreen
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.brandDeepGreen
                            : AppColors.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final effectiveValue = items.contains(value) ? value : items.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
          value: effectiveValue,
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
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
