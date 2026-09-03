import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum IngredientSourceType { labReport, noLabReport }

class IngredientSourceSegmentedControl extends StatelessWidget {
  const IngredientSourceSegmentedControl({
    super.key,
    required this.selectedSource,
    required this.onSourceChanged,
    this.onUploadLabReportTap,
    this.uploadedReportName,
    this.isAnalyzingReport = false,
  });

  final IngredientSourceType selectedSource;
  final ValueChanged<IngredientSourceType> onSourceChanged;
  final VoidCallback? onUploadLabReportTap;
  final String? uploadedReportName;
  final bool isAnalyzingReport;

  @override
  Widget build(BuildContext context) {
    final isNoLabReport = selectedSource == IngredientSourceType.noLabReport;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segmented Control Bar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Option 1: I have a lab report / CoA
              Expanded(
                child: _buildSegmentButton(
                  title: '✓ Lab Report / CoA',
                  isSelected: selectedSource == IngredientSourceType.labReport,
                  onTap: () => onSourceChanged(IngredientSourceType.labReport),
                ),
              ),
              const SizedBox(width: 4),
              // Option 2: Manual / No lab report
              Expanded(
                child: _buildSegmentButton(
                  title: 'Manual / No Report',
                  isSelected: isNoLabReport,
                  onTap: () =>
                      onSourceChanged(IngredientSourceType.noLabReport),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Lab Report Upload Box (When Lab Report is selected)
        if (selectedSource == IngredientSourceType.labReport)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF86EFAC),
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15803D).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.document_scanner_rounded,
                        color: Color(0xFF15803D),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Accredited Lab Report / CoA Auto-Scanner',
                            style: TextStyle(
                              color: Color(0xFF166534),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Upload PDF, JPG or PNG test report to extract ingredients, percentages, allergens & CoA metrics automatically.',
                            style: TextStyle(
                              color: Color(0xFF1E3A1E),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Supported formats: PDF · JPG · PNG',
                            style: TextStyle(
                              color: Color(0xFF15803D),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Upload or status action
                if (isAnalyzingReport)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: const [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF15803D),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Scanning Lab Report & Auto-Detecting Ingredients...',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (uploadedReportName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF15803D),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                uploadedReportName!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Report Verified • Ingredients & Allergens Auto-Extracted',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF15803D),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: onUploadLabReportTap,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF15803D),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 0),
                          ),
                          child: const Text(
                            'Re-upload',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onUploadLabReportTap,
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: const Text(
                        'Upload Lab Report',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
            ),
          )
        else
          // Info Callout Card for manual entry
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
                const Expanded(
                  child: Text(
                    "Manual formulation mode: add your recipe ingredients below in descending order of weight.",
                    style: TextStyle(
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
            color: isSelected
                ? AppColors.brandDeepGreen
                : Colors.transparent,
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
