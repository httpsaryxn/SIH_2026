import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum IngredientSourceType { labReport, noLabReport }

class IngredientSourceSegmentedControl extends StatelessWidget {
  const IngredientSourceSegmentedControl({
    super.key,
    required this.selectedSource,
    required this.onSourceChanged,
  });

  final IngredientSourceType selectedSource;
  final ValueChanged<IngredientSourceType> onSourceChanged;

  @override
  Widget build(BuildContext context) {
    final isNoLabReport = selectedSource == IngredientSourceType.noLabReport;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segmented Control Pill Bar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Option 1: I have a lab report
              Expanded(
                child: _buildSegmentButton(
                  title: 'I have a lab report',
                  isSelected: selectedSource == IngredientSourceType.labReport,
                  onTap: () => onSourceChanged(IngredientSourceType.labReport),
                ),
              ),
              const SizedBox(width: 4),
              // Option 2: No lab report
              Expanded(
                child: _buildSegmentButton(
                  title: 'No lab report',
                  isSelected: isNoLabReport,
                  onTap: () =>
                      onSourceChanged(IngredientSourceType.noLabReport),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Info Callout Card
        Container(
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.brandBlue.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_rounded,
                color: AppColors.brandBlue,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isNoLabReport
                      ? "We'll help you compile ingredients manually. Ensure you have your raw material specifications handy."
                      : "Upload your accredited laboratory test report or certificate of analysis to auto-extract ingredient values.",
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.brandDeepGreen, Color(0xFF004018)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.brandDeepGreen.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
