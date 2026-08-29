import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class ScanHeroCard extends StatelessWidget {
  final VoidCallback onScanPressed;
  final VoidCallback onUploadPressed;

  const ScanHeroCard({
    super.key,
    required this.onScanPressed,
    required this.onUploadPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 640;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
        boxShadow: AppSpacing.cardHoverShadow,
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.roundedMd,
        child: Stack(
          children: [
            // Background ambient glow
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                ),
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: isMobile ? _buildMobileLayout(context) : _buildDesktopLayout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderBadge(),
        const SizedBox(height: AppSpacing.md),
        _buildTextContent(),
        const SizedBox(height: AppSpacing.md),
        _buildViewfinderPreview(),
        const SizedBox(height: AppSpacing.md),
        _build3StepGuide(),
        const SizedBox(height: AppSpacing.lg),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Column: Text, 3-step value prop & CTA Buttons
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeaderBadge(),
              const SizedBox(height: AppSpacing.md),
              _buildTextContent(),
              const SizedBox(height: AppSpacing.md),
              _build3StepGuide(),
              const SizedBox(height: AppSpacing.lg),
              _buildActionButtons(context),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xl),

        // Right Column: Viewfinder Graphic
        Expanded(
          flex: 2,
          child: _buildViewfinderPreview(),
        ),
      ],
    );
  }

  Widget _buildHeaderBadge() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.2),
        borderRadius: AppSpacing.roundedDefault,
      ),
      child: const Center(
        child: Icon(
          Icons.document_scanner_rounded,
          color: AppColors.primary,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scan a Product Label',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Point your camera at a product label to get a simple summary of its ingredients, nutrition and key declarations.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _build3StepGuide() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildStepBadge('1', 'Scan label'),
        const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.outline),
        _buildStepBadge('2', 'AI analyzes'),
        const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.outline),
        _buildStepBadge('3', 'View summary'),
      ],
    );
  }

  Widget _buildStepBadge(String number, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        // Primary CTA: Scan Label
        ElevatedButton.icon(
          onPressed: onScanPressed,
          icon: const Icon(Icons.photo_camera_rounded, size: 20),
          label: Text(
            'Scan Label',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            shape: const RoundedRectangleBorder(
              borderRadius: AppSpacing.roundedDefault,
            ),
            elevation: 2,
          ),
        ),

        // Secondary CTA: Upload Image
        OutlinedButton.icon(
          onPressed: onUploadPressed,
          icon: const Icon(Icons.upload_file_rounded, size: 18, color: AppColors.onSurface),
          label: Text(
            'Upload Image',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.outlineVariant, width: 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: const RoundedRectangleBorder(
              borderRadius: AppSpacing.roundedDefault,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewfinderPreview() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedDefault,
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer dashed scanning border
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: AppSpacing.roundedDefault,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
            ),
            // Inner icon badge
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: AppSpacing.roundedSm,
                boxShadow: AppSpacing.cardHoverShadow,
              ),
              child: const Center(
                child: Icon(
                  Icons.center_focus_strong_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
