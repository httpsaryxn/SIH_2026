import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/consumer_scan_model.dart';

class RecentScansSection extends StatelessWidget {
  final List<ConsumerScanModel> scans;
  final bool isLoading;
  final Function(ConsumerScanModel scan) onScanTap;
  final VoidCallback onViewAllTap;

  const RecentScansSection({
    super.key,
    required this.scans,
    this.isLoading = false,
    required this.onScanTap,
    required this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Recently Scanned',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
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

        // Scans Content
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (scans.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, color: AppColors.outline, size: 40),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No products scanned yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scan a product packaging label to check its Legal Metrology compliance.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 540;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: scans.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 2 : 1,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  mainAxisExtent: 154,
                ),
                itemBuilder: (context, index) {
                  final scan = scans[index];
                  return _buildScanCard(context, scan);
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildScanCard(BuildContext context, ConsumerScanModel scan) {
    final isCompliant = scan.complianceStatus == 'compliant';
    final isWarning = scan.complianceStatus == 'warning';

    Color badgeBg;
    Color badgeText;
    IconData badgeIcon;
    String badgeLabel;

    if (isCompliant) {
      badgeBg = AppColors.primaryFixed.withValues(alpha: 0.25);
      badgeText = AppColors.onPrimaryContainer;
      badgeIcon = Icons.check_circle_rounded;
      badgeLabel = 'No issues';
    } else if (isWarning) {
      badgeBg = AppColors.errorContainer;
      badgeText = AppColors.onErrorContainer;
      badgeIcon = Icons.warning_rounded;
      badgeLabel = 'Potential issue';
    } else {
      badgeBg = AppColors.surfaceContainerHigh;
      badgeText = AppColors.onSurfaceVariant;
      badgeIcon = Icons.help_outline_rounded;
      badgeLabel = 'Unverified';
    }

    return InkWell(
      onTap: () => onScanTap(scan),
      borderRadius: AppSpacing.roundedMd,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(
            color: isWarning ? AppColors.errorContainer : AppColors.surfaceVariant,
            width: 1,
          ),
          boxShadow: AppSpacing.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Image Thumbnail & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Thumbnail
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: AppSpacing.roundedDefault,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: scan.imageUrl != null && scan.imageUrl!.isNotEmpty
                      ? Image.network(
                          scan.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.fastfood_rounded,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.fastfood_rounded,
                          color: AppColors.primary,
                        ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: AppSpacing.roundedFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, color: badgeText, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        badgeLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: badgeText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Product Name
            Text(
              scan.productName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Brand & Quantity
            Text(
              '${scan.brand} • ${scan.netQuantity}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),

            // Time Ago
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text(
                  'Scanned ${scan.timeAgo}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.secondary,
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
