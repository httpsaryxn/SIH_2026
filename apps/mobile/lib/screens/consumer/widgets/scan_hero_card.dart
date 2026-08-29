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
        boxShadow: AppSpacing.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.roundedMd,
        child: Stack(
          children: [
            // Decorative background radial blur
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconBadge(),
        const SizedBox(height: AppSpacing.md),
        _buildTextContent(),
        const SizedBox(height: AppSpacing.md),
        _buildViewfinderPreview(),
        const SizedBox(height: AppSpacing.lg),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Column: Text & CTA Buttons
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIconBadge(),
              const SizedBox(height: AppSpacing.md),
              _buildTextContent(),
              const SizedBox(height: AppSpacing.lg),
              _buildActionButtons(),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),

        // Right Column: Viewfinder Graphic
        Expanded(
          flex: 2,
          child: _buildViewfinderPreview(),
        ),
      ],
    );
  }

  Widget _buildIconBadge() {
    return Container(
      width: 48,
      height: 48,
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
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Use your camera to instantly analyze nutritional facts, ingredients, and detect potential anomalies under Legal Metrology rules.',
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

  Widget _buildActionButtons() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        // Scan Label Button
        ElevatedButton.icon(
          onPressed: onScanPressed,
          icon: const Icon(Icons.photo_camera_rounded, size: 18),
          label: const Text('Scan Label'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: const RoundedRectangleBorder(
              borderRadius: AppSpacing.roundedDefault,
            ),
            elevation: 0,
          ),
        ),

        // Upload Image Button
        OutlinedButton.icon(
          onPressed: onUploadPressed,
          icon: const Icon(Icons.upload_file_rounded, size: 18, color: AppColors.onSurface),
          label: Text(
            'Upload Image',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.outlineVariant),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedDefault,
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer dashed box
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                borderRadius: AppSpacing.roundedDefault,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            ),
            // Inner icon badge
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: AppSpacing.roundedSm,
                boxShadow: AppSpacing.cardShadow,
              ),
              child: const Center(
                child: Icon(
                  Icons.center_focus_strong_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
