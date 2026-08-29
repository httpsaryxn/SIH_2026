import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class ReportIssueHeroCard extends StatelessWidget {
  final VoidCallback onReportTap;

  const ReportIssueHeroCard({super.key, required this.onReportTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.onTertiaryFixed, // Deep Slate / Navy background
        borderRadius: AppSpacing.roundedMd,
        boxShadow: AppSpacing.cardHoverShadow,
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.roundedMd,
        child: Stack(
          children: [
            // Abstract shape glow in background
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tertiary.withValues(alpha: 0.25),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.report_problem_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Title
                  Text(
                    'See something wrong?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Description
                  Text(
                    'Report a potentially misleading or non-compliant label directly to the Legal Metrology authorities.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.tertiaryFixedDim,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onReportTap,
                      icon: const Icon(
                        Icons.campaign_rounded,
                        size: 18,
                        color: AppColors.onTertiaryFixed,
                      ),
                      label: Text(
                        'Report an Issue',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onTertiaryFixed,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.onTertiaryFixed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedDefault,
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
