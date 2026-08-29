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

  const MyComplaintsSection({
    super.key,
    required this.complaints,
    this.isLoading = false,
    required this.onComplaintTap,
    required this.onViewAllTap,
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
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
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
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'No complaints submitted yet.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
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
                      'View All Complaints',
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
      case 'action_taken':
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
            // Top Row: Category + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    complaint.issueCategory,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: AppSpacing.roundedFull,
                  ),
                  child: Text(
                    complaint.displayStatus,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),

            // Product Name
            Text(
              complaint.productName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // ID & Date
            Text(
              'ID: ${complaint.complaintCode} • ${complaint.formattedDate}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
