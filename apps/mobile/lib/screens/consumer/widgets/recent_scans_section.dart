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
  final VoidCallback onScanNewTap;

  const RecentScansSection({
    super.key,
    required this.scans,
    this.isLoading = false,
    required this.onScanTap,
    required this.onViewAllTap,
    required this.onScanNewTap,
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
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            if (scans.isNotEmpty)
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
          // Empty State Matching Prompt Requirements
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: AppColors.surfaceVariant),
              boxShadow: AppSpacing.cardShadow,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No products scanned yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scan your first product to see its ingredients, nutrition and label summary.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: onScanNewTap,
                    icon: const Icon(Icons.photo_camera_rounded, size: 18),
                    label: const Text('Scan Label'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedDefault,
                      ),
                      elevation: 0,
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
                  mainAxisExtent: 172,
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
    final isWarning = scan.complianceStatus == 'warning' || scan.complianceStatus == 'potential_violation';

    Color badgeBg;
    Color badgeText;
    IconData badgeIcon;
    String badgeLabel;

    if (isCompliant) {
      badgeBg = AppColors.primaryFixed.withValues(alpha: 0.25);
      badgeText = AppColors.onPrimaryContainer;
      badgeIcon = Icons.check_circle_rounded;
      badgeLabel = 'Label Check: No obvious issue detected';
    } else if (isWarning) {
      badgeBg = AppColors.errorContainer;
      badgeText = AppColors.onErrorContainer;
      badgeIcon = Icons.warning_rounded;
      badgeLabel = 'Potential issue detected';
    } else {
      badgeBg = AppColors.surfaceContainerHigh;
      badgeText = AppColors.onSurfaceVariant;
      badgeIcon = Icons.help_outline_rounded;
      badgeLabel = 'Unverified label';
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
            // Top Row: Thumbnail + Date Info
            Row(
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
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scan.productName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${scan.brand} • ${scan.netQuantity}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
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
            const SizedBox(height: AppSpacing.xs),

            // Compliance Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: AppSpacing.roundedSm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, color: badgeText, size: 12),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      badgeLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: badgeText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Bottom Row: Date Scanned & View Summary CTA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 12, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Scanned ${scan.timeAgo}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'View Summary →',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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
