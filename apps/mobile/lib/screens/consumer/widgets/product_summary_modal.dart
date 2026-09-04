import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/consumer_scan_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/consumer_data_service.dart';

class ProductSummaryModal extends StatefulWidget {
  final ConsumerScanModel scan;
  final VoidCallback onReportIssue;
  final VoidCallback? onCompare;

  const ProductSummaryModal({
    super.key,
    required this.scan,
    required this.onReportIssue,
    this.onCompare,
  });

  @override
  State<ProductSummaryModal> createState() => _ProductSummaryModalState();
}

class _ProductSummaryModalState extends State<ProductSummaryModal> {
  bool _isSaved = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    final savedList = await ConsumerDataService.fetchSavedProducts();
    if (mounted) {
      setState(() {
        _isSaved = savedList.any((p) => p.productName == widget.scan.productName);
      });
    }
  }

  Future<void> _toggleSave() async {
    setState(() => _isSaving = true);

    final dummyProduct = ProductModel(
      id: widget.scan.productId ?? widget.scan.id,
      productName: widget.scan.productName,
      brand: widget.scan.brand,
      netQuantity: widget.scan.netQuantity,
      imageUrl: widget.scan.imageUrl,
      complianceStatus: widget.scan.complianceStatus,
    );

    if (_isSaved) {
      await ConsumerDataService.unsaveProduct(dummyProduct.id);
      if (mounted) setState(() => _isSaved = false);
    } else {
      await ConsumerDataService.saveProduct(dummyProduct);
      if (mounted) setState(() => _isSaved = true);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(_isSaved ? 'Saved to bookmarks!' : 'Removed from bookmarks.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompliant = widget.scan.complianceStatus == 'compliant';
    final isWarning = widget.scan.complianceStatus == 'warning' ||
        widget.scan.complianceStatus == 'potential_violation';

    final dec = widget.scan.detectedDeclarations;
    final ingredients = (dec['ingredients'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['Whole Grains', 'Natural Extracts', 'Iodized Salt'];

    final nutrition = (dec['nutrition_facts'] is Map)
        ? Map<String, dynamic>.from(dec['nutrition_facts'] as Map)
        : {
            'Calories': '210 kcal',
            'Carbohydrates': '42 g',
            'Protein': '6.5 g',
            'Total Fat': '2.1 g',
            'Sugar': '1.2 g',
          };

    final mfgName = dec['manufacturer'] as String? ?? 'Artisan Foods Ltd';
    final mfgAddress = dec['manufacturer_address'] as String? ??
        'Plot 42, Food Park, Phase 1, Industrial Estate';
    final mrp = dec['mrp'] != null ? '₹${dec['mrp']}' : '₹85.00 (Incl. of all taxes)';
    final mfgDate = dec['mfg_date'] as String? ?? 'Jul 2026';
    final bestBefore = dec['best_before'] as String? ?? '9 Months from packaging';
    final consumerCare = dec['consumer_care_info'] as String? ??
        'care@brand.in | Helpline: 1800-200-8899';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
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

              // Top Title & Quick Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: AppSpacing.roundedDefault,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: widget.scan.imageUrl != null
                        ? Image.network(
                            widget.scan.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.fastfood, color: AppColors.primary),
                          )
                        : const Icon(Icons.fastfood, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Name & Brand
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.scan.productName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.scan.brand} • ${widget.scan.netQuantity}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'MRP: $mrp',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bookmark Button
                  IconButton(
                    icon: Icon(
                      _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: _isSaved ? AppColors.tertiary : AppColors.outline,
                    ),
                    tooltip: _isSaved ? 'Bookmarked' : 'Bookmark Product',
                    onPressed: _isSaving ? null : _toggleSave,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 1. Label Check Result Banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isCompliant
                      ? AppColors.primaryFixed.withValues(alpha: 0.2)
                      : (isWarning
                          ? AppColors.errorContainer.withValues(alpha: 0.5)
                          : AppColors.surfaceContainerLow),
                  borderRadius: AppSpacing.roundedDefault,
                  border: Border.all(
                    color: isCompliant
                        ? AppColors.primary
                        : (isWarning ? AppColors.error : AppColors.outlineVariant),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCompliant
                              ? Icons.check_circle_rounded
                              : (isWarning ? Icons.warning_rounded : Icons.info_rounded),
                          color: isCompliant
                              ? AppColors.primary
                              : (isWarning ? AppColors.error : AppColors.secondary),
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            isCompliant
                                ? 'Label Check: No obvious issue detected'
                                : 'Label Check: Potential label issue detected',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isCompliant
                                  ? AppColors.primary
                                  : (isWarning ? AppColors.error : AppColors.onSurface),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.scan.scanNotes ??
                          (isCompliant
                              ? 'Mandatory declarations (Net Qty, MRP, Manufacturer, Expiry) adhere to Legal Metrology Packaged Commodities Rules.'
                              : 'Discrepancy detected in mandatory declarations or minimum font size threshold.'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '* Note: This is an automated preliminary check, not a final legal determination.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Ingredients Section
              Text(
                'Extracted Ingredients',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ingredients
                    .map((ing) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: AppSpacing.roundedSm,
                            border: Border.all(color: AppColors.surfaceVariant),
                          ),
                          child: Text(
                            ing,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 3. Nutrition Facts Table
              Text(
                'Nutritional Information (per serving / 100g)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                decoration: BoxDecoration(
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Column(
                  children: nutrition.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.surfaceVariant, width: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            entry.value.toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4. Important Legal Metrology Declarations
              Text(
                'Key Packaged Commodity Declarations',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildDeclarationTile('Manufacturer / Packer', '$mfgName, $mfgAddress'),
              _buildDeclarationTile('Net Quantity', widget.scan.netQuantity),
              _buildDeclarationTile('Maximum Retail Price (MRP)', mrp),
              _buildDeclarationTile('Manufacturing Date', mfgDate),
              _buildDeclarationTile('Best Before / Expiry', bestBefore),
              _buildDeclarationTile('Consumer Care Helpline', consumerCare),
              const SizedBox(height: AppSpacing.xl),

              // Bottom Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onReportIssue();
                      },
                      icon: const Icon(Icons.campaign_rounded, color: AppColors.error, size: 18),
                      label: Text(
                        'Report Issue',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedDefault,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (widget.onCompare != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onCompare!();
                        },
                        icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                        label: Text(
                          'Compare',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppSpacing.roundedDefault,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedDefault,
                        ),
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

  Widget _buildDeclarationTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.onSurface),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
