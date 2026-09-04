import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/consumer_complaint_model.dart';

class MyComplaintsSection extends StatelessWidget {
  final List<ConsumerComplaintModel> complaints;
  final bool isLoading;
  final Function(ConsumerComplaintModel complaint) onComplaintTap;
  final VoidCallback onViewAllTap;
  final VoidCallback onReportNewTap;

  const MyComplaintsSection({
    super.key,
    required this.complaints,
    this.isLoading = false,
    required this.onComplaintTap,
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
            children: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (complaints.isEmpty)
                // Empty state matching prompt
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
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
                          'If you spot an incorrect MRP, missing net quantity, or misleading declaration, report it here.',
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
                )
              else
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
              if (complaints.isNotEmpty)
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
          ),
        ),
      ],
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
