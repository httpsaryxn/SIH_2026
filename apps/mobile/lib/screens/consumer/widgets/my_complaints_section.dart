import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/consumer_complaint_model.dart';
import '../../../core/models/consumer_scan_model.dart';

class MyComplaintsSection extends StatelessWidget {
  final List<ConsumerComplaintModel> complaints;
  final List<ConsumerScanModel> recentScans;
  final bool isLoading;
  final Function(ConsumerComplaintModel complaint) onComplaintTap;
  final Function(ConsumerScanModel scan)? onReportScan;
  final VoidCallback onViewAllTap;
  final VoidCallback onReportNewTap;

  const MyComplaintsSection({
    super.key,
    required this.complaints,
    this.recentScans = const [],
    this.isLoading = false,
    required this.onComplaintTap,
    this.onReportScan,
    required this.onViewAllTap,
    required this.onReportNewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.gavel_rounded, color: AppColors.secondary, size: 22),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'My Complaints',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            if (complaints.isNotEmpty)
              TextButton(
                onPressed: onViewAllTap,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Complaints Card Container
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: AppColors.surfaceVariant, width: 1),
            boxShadow: AppSpacing.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (complaints.isEmpty) ...[
                if (recentScans.isNotEmpty) ...[
                  // If no formal complaints filed yet, show recently scanned products ready to report!
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: AppColors.surfaceContainerLow,
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No filed complaints yet. Report an issue with any recently scanned product below:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentScans.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: AppColors.surfaceVariant,
                    ),
                    itemBuilder: (context, index) {
                      final scan = recentScans[index];
                      return _buildRecentScanTile(context, scan);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: OutlinedButton.icon(
                      onPressed: onReportNewTap,
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: const Text('File Custom / Other Complaint'),
                    ),
                  ),
                ] else ...[
                  // Empty state when both complaints and recent scans are empty
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.assignment_turned_in_outlined,
                                  color: AppColors.secondary, size: 24),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            "You haven't submitted any complaints",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Scan a product first to check compliance or report an incorrect MRP, missing net quantity, or misleading declaration.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton(
                            onPressed: onReportNewTap,
                            child: const Text('Report an Issue'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ] else ...[
                // Recent Scans quick-bar if user has submitted complaints too
                if (recentScans.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      border: Border(
                        bottom: BorderSide(color: AppColors.surfaceVariant, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.qr_code_scanner_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              '${recentScans.length} Recent Scans Available',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            if (recentScans.isNotEmpty && onReportScan != null) {
                              onReportScan!(recentScans.first);
                            } else {
                              onReportNewTap();
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            '+ Report Scan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: complaints.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: AppColors.surfaceVariant,
                  ),
                  itemBuilder: (context, index) {
                    final complaint = complaints[index];
                    return _buildComplaintTile(context, complaint);
                  },
                ),
                // Bottom View All Link
                InkWell(
                  onTap: onViewAllTap,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.surfaceVariant, width: 1),
                      ),
                      color: AppColors.surfaceContainerLow,
                    ),
                    child: Center(
                      child: Text(
                        'View All Complaints (${complaints.length})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentScanTile(BuildContext context, ConsumerScanModel scan) {
    final isCompliant = scan.complianceStatus == 'compliant';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: scan.imageUrl != null && scan.imageUrl!.isNotEmpty
                ? Image.network(
                    scan.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 48,
                      height: 48,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.inventory_2_outlined, size: 24),
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.inventory_2_outlined, size: 24),
                  ),
          ),
          const SizedBox(width: 12),

          // Title & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${scan.brand} • ${scan.netQuantity}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCompliant
                        ? AppColors.primaryContainer.withValues(alpha: 0.25)
                        : AppColors.errorContainer.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isCompliant ? 'No obvious issue detected' : 'Flagged Issue Detected',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isCompliant ? AppColors.primary : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Report Issue Button
          ElevatedButton.icon(
            onPressed: () => onReportScan?.call(scan),
            icon: const Icon(Icons.campaign_outlined, size: 15),
            label: const Text('Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorContainer.withValues(alpha: 0.6),
              foregroundColor: AppColors.error,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.error, width: 1),
              ),
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintTile(BuildContext context, ConsumerComplaintModel complaint) {
    Color statusBg;
    Color statusText;

    switch (complaint.status) {
      case 'under_review':
        statusBg = AppColors.tertiaryFixed;
        statusText = AppColors.onTertiaryFixedVariant;
        break;
      case 'forwarded_to_company':
        statusBg = AppColors.secondaryContainer;
        statusText = AppColors.onSecondaryContainer;
        break;
      case 'action_required':
        statusBg = AppColors.errorContainer.withValues(alpha: 0.7);
        statusText = AppColors.onErrorContainer;
        break;
      case 'verified':
      case 'resolved':
        statusBg = AppColors.primaryFixed.withValues(alpha: 0.3);
        statusText = AppColors.onPrimaryContainer;
        break;
      case 'rejected':
        statusBg = AppColors.errorContainer;
        statusText = AppColors.onErrorContainer;
        break;
      case 'submitted':
      default:
        statusBg = AppColors.surfaceContainerHighest;
        statusText = AppColors.onSurfaceVariant;
        break;
    }

    return InkWell(
      onTap: () => onComplaintTap(complaint),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Complaint Code + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  complaint.complaintCode,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: AppSpacing.roundedFull,
                  ),
                  child: Text(
                    complaint.displayStatus,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Product Name & Issue
            Text(
              complaint.productName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'Issue: ${complaint.issueCategory}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Submitted Date & View Timeline Link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Submitted ${complaint.formattedDate}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  'Track Timeline →',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
