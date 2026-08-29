import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/consumer_scan_model.dart';

class ProductSummaryModal extends StatelessWidget {
  final ConsumerScanModel scan;
  final VoidCallback onReportIssue;

  const ProductSummaryModal({
    super.key,
    required this.scan,
    required this.onReportIssue,
  });

  @override
  Widget build(BuildContext context) {
    final isCompliant = scan.complianceStatus == 'compliant';
    final isWarning = scan.complianceStatus == 'warning';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Top row: Title + Close
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scan.productName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${scan.brand} • ${scan.netQuantity}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Compliance Banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isCompliant
                      ? AppColors.primaryFixed.withValues(alpha: 0.2)
                      : (isWarning ? AppColors.errorContainer.withValues(alpha: 0.5) : AppColors.surfaceContainerLow),
                  borderRadius: AppSpacing.roundedDefault,
                  border: Border.all(
                    color: isCompliant ? AppColors.primary : (isWarning ? AppColors.error : AppColors.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCompliant ? Icons.check_circle_rounded : (isWarning ? Icons.warning_rounded : Icons.info_rounded),
                      color: isCompliant ? AppColors.primary : (isWarning ? AppColors.error : AppColors.secondary),
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCompliant ? 'Compliant with Legal Metrology' : (isWarning ? 'Potential Compliance Issue Detected' : 'Unverified declarations'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isCompliant ? AppColors.primary : (isWarning ? AppColors.error : AppColors.onSurface),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            scan.scanNotes ?? 'Checked against Packaging Rules, 2011.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Declarations Check Section
              Text(
                'Legal Metrology Declarations',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDeclarationRow('Net Quantity', scan.netQuantity, true),
              _buildDeclarationRow('Manufacturer Details', 'Verified on package', true),
              _buildDeclarationRow('Customer Care Info', 'Email & Helpline printed', true),
              _buildDeclarationRow('Font Size Standards', isCompliant ? 'Meets min 1.5mm req.' : 'Below minimum threshold', isCompliant),
              const SizedBox(height: AppSpacing.lg),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onReportIssue();
                      },
                      icon: const Icon(Icons.campaign_rounded, color: AppColors.error, size: 18),
                      label: Text(
                        'Report Issue',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedDefault),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedDefault),
                        elevation: 0,
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
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

  Widget _buildDeclarationRow(String label, String value, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Row(
            children: [
              Icon(
                isValid ? Icons.check_rounded : Icons.close_rounded,
                size: 16,
                color: isValid ? AppColors.primary : AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
