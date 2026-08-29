import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/consumer_saved_product.dart';

class SavedProductsSection extends StatelessWidget {
  final List<ConsumerSavedProduct> savedProducts;
  final bool isLoading;
  final Function(ConsumerSavedProduct item) onProductTap;
  final Function(ConsumerSavedProduct item) onUnsaveTap;

  const SavedProductsSection({
    super.key,
    required this.savedProducts,
    this.isLoading = false,
    required this.onProductTap,
    required this.onUnsaveTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.bookmark_rounded, color: AppColors.tertiary, size: 22),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Saved Products',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // List Content
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (savedProducts.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Center(
              child: Text(
                'No saved items. Bookmark products to access them quickly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: AppColors.surfaceVariant, width: 1),
              boxShadow: AppSpacing.cardShadow,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: savedProducts.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppColors.surfaceVariant,
              ),
              itemBuilder: (context, index) {
                final item = savedProducts[index];
                return _buildSavedTile(context, item);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSavedTile(BuildContext context, ConsumerSavedProduct item) {
    return InkWell(
      onTap: () => onProductTap(item),
      borderRadius: AppSpacing.roundedMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Category / Item Icon Container
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.tertiaryFixed,
                borderRadius: AppSpacing.roundedSm,
              ),
              child: const Center(
                child: Icon(
                  Icons.water_drop_rounded,
                  color: AppColors.onTertiaryFixed,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Product Name & Brand
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
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
                    '${item.brand} • ${item.quantity ?? ''}',
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

            // Bookmark Action Button
            IconButton(
              icon: const Icon(
                Icons.bookmark_rounded,
                color: AppColors.tertiary,
                size: 22,
              ),
              tooltip: 'Remove bookmark',
              onPressed: () => onUnsaveTap(item),
            ),
          ],
        ),
      ),
    );
  }
}
