import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/consumer_data_service.dart';

class ProductComparisonModal extends StatefulWidget {
  final ProductModel? initialProduct1;
  final ProductModel? initialProduct2;

  const ProductComparisonModal({
    super.key,
    this.initialProduct1,
    this.initialProduct2,
  });

  @override
  State<ProductComparisonModal> createState() => _ProductComparisonModalState();
}

class _ProductComparisonModalState extends State<ProductComparisonModal> {
  List<ProductModel> _allProducts = [];
  bool _isLoading = true;
  ProductModel? _product1;
  ProductModel? _product2;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final catalog = await ConsumerDataService.fetchProductsCatalog();
    if (mounted) {
      setState(() {
        _allProducts = catalog;
        if (catalog.isNotEmpty) {
          _product1 = widget.initialProduct1 ?? catalog[0];
          _product2 = widget.initialProduct2 ??
              (catalog.length > 1 ? catalog[1] : catalog[0]);
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
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

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.compare_arrows_rounded,
                                color: AppColors.primary, size: 24),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Product Comparison',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Side-by-side comparison of nutrition, ingredients, and compliance.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Selectors for Product A and Product B
                    Row(
                      children: [
                        Expanded(
                          child: _buildProductDropdown(
                            'Product A',
                            _product1,
                            (p) => setState(() => _product1 = p),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildProductDropdown(
                            'Product B',
                            _product2,
                            (p) => setState(() => _product2 = p),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    if (_product1 != null && _product2 != null) ...[
                      // Comparison Table
                      _buildComparisonRow(
                        'Compliance Status',
                        _product1!.labelStatusText,
                        _product2!.labelStatusText,
                        highlight: true,
                        isWarning1: _product1!.complianceStatus != 'compliant',
                        isWarning2: _product2!.complianceStatus != 'compliant',
                      ),
                      _buildComparisonRow(
                        'Net Quantity',
                        _product1!.netQuantity ?? '-',
                        _product2!.netQuantity ?? '-',
                      ),
                      _buildComparisonRow(
                        'MRP (Price)',
                        _product1!.mrp != null ? '₹${_product1!.mrp}' : '-',
                        _product2!.mrp != null ? '₹${_product2!.mrp}' : '-',
                      ),
                      _buildComparisonRow(
                        'Calories',
                        _product1!.nutritionFacts['calories']?.toString() ?? '220 kcal',
                        _product2!.nutritionFacts['calories']?.toString() ?? '380 kcal',
                      ),
                      _buildComparisonRow(
                        'Protein',
                        _product1!.nutritionFacts['protein']?.toString() ?? '8 g',
                        _product2!.nutritionFacts['protein']?.toString() ?? '6 g',
                      ),
                      _buildComparisonRow(
                        'Carbohydrates',
                        _product1!.nutritionFacts['carbohydrates']?.toString() ?? '44 g',
                        _product2!.nutritionFacts['carbohydrates']?.toString() ?? '78 g',
                      ),
                      _buildComparisonRow(
                        'Fat',
                        _product1!.nutritionFacts['fat']?.toString() ?? '1.2 g',
                        _product2!.nutritionFacts['fat']?.toString() ?? '4.8 g',
                      ),
                      _buildComparisonRow(
                        'Manufacturer',
                        _product1!.manufacturerName ?? _product1!.brand,
                        _product2!.manufacturerName ?? _product2!.brand,
                      ),
                      _buildComparisonRow(
                        'Ingredients Count',
                        '${_product1!.ingredients.length} items',
                        '${_product2!.ingredients.length} items',
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedDefault,
                        ),
                      ),
                      child: const Text('Close Comparison'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProductDropdown(
    String label,
    ProductModel? selected,
    Function(ProductModel?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<ProductModel>(
          initialValue: selected,
          isExpanded: true,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          items: _allProducts
              .map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(
                      p.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildComparisonRow(
    String label,
    String val1,
    String val2, {
    bool highlight = false,
    bool isWarning1 = false,
    bool isWarning2 = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceVariant, width: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  val1,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                    color: isWarning1 ? AppColors.error : AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  val2,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                    color: isWarning2 ? AppColors.error : AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
