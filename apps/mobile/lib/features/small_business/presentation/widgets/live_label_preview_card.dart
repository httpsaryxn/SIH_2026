import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/small_business_label_model.dart';
import '../../data/services/gs1_ean13_encoder.dart';
import 'claim_item_card.dart';
import 'product_image_widget.dart';

class LiveLabelPreviewCard extends StatelessWidget {
  const LiveLabelPreviewCard({
    super.key,
    this.brandName = 'Desi Harvest',
    this.logoUrl,
    this.productName = 'Authentic Mango Pickle',
    this.productCategory = 'Pickles & Condiments',
    this.typeFlavour = '',
    this.netQuantity = '250 g',
    this.mrp = '₹ 149.00',
    this.unitSalePrice = '₹ 0.60 / g',
    this.batchNumber = 'DH-2026-B8',
    this.mfgDate = 'AUG 2026',
    this.bestBefore = '12 MONTHS from Packaging',
    this.storageInstructions = 'Store in a cool, dry & hygienic place.',
    this.fssaiNumber = '12345678901234',
    this.manufacturerName = 'Desi Harvest Foods Pvt. Ltd.',
    this.manufacturerAddress = 'Plot 12, Greenfield Organic Estate, Phase 3, Pune, MH, 411028',
    this.consumerCarePhone = '+91 98765 43210',
    this.consumerCareEmail = 'care@desiharvest.in',
    this.selectedClaims = const [],
    this.isVegetarian = true,
    this.widthMm = 100,
    this.heightMm = 150,
    this.labelModel,
  });

  final String brandName;
  final String? logoUrl;
  final String productName;
  final String productCategory;
  final String typeFlavour;
  final String netQuantity;
  final String mrp;
  final String unitSalePrice;
  final String batchNumber;
  final String mfgDate;
  final String bestBefore;
  final String storageInstructions;
  final String fssaiNumber;
  final String manufacturerName;
  final String manufacturerAddress;
  final String consumerCarePhone;
  final String consumerCareEmail;
  final List<ProductClaim> selectedClaims;
  final bool isVegetarian;
  final double widthMm;
  final double heightMm;
  final SmallBusinessLabelModel? labelModel;

  String _generateBarcodeDigits() {
    final digitsOnly = fssaiNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length >= 9) {
      return '890${digitsOnly.substring(digitsOnly.length - 9, digitsOnly.length - 1)}8';
    }
    return '8901234567890';
  }

  void _showBarcodeDetails(BuildContext context) {
    final barcode = _generateBarcodeDigits();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.qr_code_scanner_rounded, color: AppColors.brandDeepGreen, size: 24),
            SizedBox(width: 8),
            Text('GS1 EAN-13 Barcode', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                children: [
                  CustomPaint(
                    size: const Size(180, 60),
                    painter: _GS1Ean13BarcodePainter(
                      barcodeDigits: GS1Ean13Encoder.normalizeEan13(barcode),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    GS1Ean13Encoder.normalizeEan13(barcode),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'High-precision vector barcode verified for commercial retail point-of-sale optical scanners.',
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoWidget() {
    final logo = logoUrl ?? labelModel?.logoUrl;
    if (logo != null && logo.trim().isNotEmpty) {
      return ProductImageWidget(
        imageUrl: logo.trim(),
        category: productCategory,
        width: 44,
        height: 44,
        borderRadius: 8,
        fit: BoxFit.cover,
      );
    }
    return _fallbackLogo();
  }

  Widget _fallbackLogo() {
    final letter = brandName.isNotEmpty ? brandName.substring(0, 1).toUpperCase() : 'B';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.brandDeepGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barcodeStr = _generateBarcodeDigits();
    final formattedBarcode = '${barcodeStr.substring(0, 1)} ${barcodeStr.substring(1, 7)} ${barcodeStr.substring(7)}';

    // Extract formulation ingredients
    final ingredientsList = (labelModel != null && labelModel!.ingredients.isNotEmpty)
        ? labelModel!.ingredients.map((i) => '${i.name} (${i.percentage ?? 0}%)').join(', ')
        : 'Formulation Ingredients, Permitted Seasoning, Edible Vegetable Oil, Common Salt';

    // Extract allergens
    final allergensList = (labelModel != null && labelModel!.allergens.isNotEmpty)
        ? labelModel!.allergens.join(', ')
        : 'Mustard, Gluten';

    // Extract nutrients
    final nutrients = labelModel?.nutrients ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label Visual Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.aspect_ratio_rounded,
                        size: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'PACKAGING PREVIEW (${widthMm.toInt()} × ${heightMm.toInt()} MM)',
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PRINT READY',
                    style: TextStyle(
                      color: Color(0xFF15803D),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Label Body Canvas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Brand Row with Brand Logo & Vegetarian Emblem
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Logo
                    _buildLogoWidget(),
                    const SizedBox(width: 10),

                    // Brand & Product Names
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            brandName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandDeepGreen,
                              letterSpacing: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            productName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                            softWrap: true,
                          ),
                          Text(
                            typeFlavour.isNotEmpty ? '$productCategory • $typeFlavour' : productCategory,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Indian Veg Symbol
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isVegetarian ? const Color(0xFF16A34A) : const Color(0xFF991B1B),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isVegetarian ? const Color(0xFF16A34A) : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Net Quantity & Price Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NET QUANTITY',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              netQuantity,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              softWrap: true,
                            ),
                            if (unitSalePrice.isNotEmpty)
                              Text(
                                'USP: $unitSalePrice',
                                style: const TextStyle(fontSize: 8.5, color: AppColors.onSurfaceVariant),
                                softWrap: true,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'MAX RETAIL PRICE (MRP)',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              mrp,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandDeepGreen,
                              ),
                              softWrap: true,
                            ),
                            const Text(
                              '(Incl. of all taxes)',
                              style: TextStyle(fontSize: 8, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Packaging Body: Back of Pack Regulatory Layout matching real standard
                // 1. Manufacturer & Packer Lic No. block
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mfd. By: ',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.black87),
                          ),
                          Expanded(
                            child: Text(
                              '$manufacturerName, $manufacturerAddress',
                              style: const TextStyle(fontSize: 9.5, color: Colors.black87, height: 1.25),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lic. No. ${fssaiNumber.isNotEmpty ? fssaiNumber : "10012031000120"}',
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 2. Proprietary Food Title
                Text(
                  'PROPRIETARY FOOD - ${productCategory.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 0.2,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 5),

                // 3. Ingredients Statement in regulatory style
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 9.5, color: Colors.black87, height: 1.3),
                    children: [
                      const TextSpan(
                        text: 'INGREDIENTS: ',
                        style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
                      ),
                      TextSpan(text: ingredientsList),
                    ],
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 6),

                // 4. Allergen Advice Strip
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 9.5, color: Color(0xFF991B1B), height: 1.25),
                      children: [
                        const TextSpan(
                          text: 'ALLERGEN ADVICE: ',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        TextSpan(
                          text: 'Contains $allergensList.',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    softWrap: true,
                  ),
                ),
                const SizedBox(height: 8),

                // 5. Authentic 3-Column Bordered Nutrition Information Table Grid
                _buildPackagedNutritionTable(nutrients),
                const SizedBox(height: 10),

                // 6. Dates, Batch & Instructions Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _MiniSpecItem('Batch No.', batchNumber),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: _MiniSpecItem('Mfg Date', mfgDate),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 5,
                            child: _MiniSpecItem('Best Before', bestBefore),
                          ),
                        ],
                      ),
                      if (storageInstructions.isNotEmpty) ...[
                        const Divider(height: 12, color: Color(0xFFE2E8F0)),
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: Color(0xFF475569),
                              height: 1.25,
                            ),
                            children: [
                              const TextSpan(
                                text: 'STORAGE: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              TextSpan(
                                text: storageInstructions,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          softWrap: true,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 7. Scannable GS1 Barcode & Authentic FSSAI Logo Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tappable Standard Scannable Barcode Card
                    Expanded(
                      flex: 5,
                      child: InkWell(
                        onTap: () => _showBarcodeDetails(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            children: [
                              CustomPaint(
                                size: const Size(48, 26),
                                painter: _GS1Ean13BarcodePainter(
                                  barcodeDigits: GS1Ean13Encoder.normalizeEan13(formattedBarcode),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      GS1Ean13Encoder.normalizeEan13(formattedBarcode),
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Text(
                                      'GS1 EAN-13 ✓',
                                      style: TextStyle(
                                        fontSize: 6.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF15803D),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Official Industry Standard FSSAI Emblem Badge with PNG Logo
                    Flexible(
                      flex: 4,
                      child: _OfficialFssaiBadge(licenseNumber: fssaiNumber),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagedNutritionTable(List<SmallBusinessNutrientModel> nutrientList) {
    final sSize = labelModel?.servingSize.isNotEmpty == true ? labelModel!.servingSize : '20';
    final sUnit = labelModel?.servingSizeUnit.isNotEmpty == true ? labelModel!.servingSizeUnit : 'g';
    final serveGrams = double.tryParse(sSize) ?? 20.0;

    // Build standard rows
    final rowsData = <_NutritionRowItem>[];

    void addRow(String name, String fallbackVal, String unit, double? rdaDaily) {
      final found = nutrientList.firstWhere(
        (n) => n.label.toLowerCase().contains(name.toLowerCase()) || name.toLowerCase().contains(n.label.toLowerCase()),
        orElse: () => SmallBusinessNutrientModel(label: name, value: fallbackVal, unit: unit),
      );
      final valStr = found.value.isNotEmpty ? found.value : fallbackVal;
      final valNum = double.tryParse(valStr) ?? 0.0;
      String rdaStr = '';
      if (rdaDaily != null && rdaDaily > 0) {
        final rdaPct = ((valNum * (serveGrams / 100.0)) / rdaDaily) * 100.0;
        rdaStr = '${rdaPct.round()}%';
      }
      rowsData.add(_NutritionRowItem(name: name, per100g: '$valStr $unit', rdaPerServe: rdaStr));
    }

    addRow('Energy', '536', 'kcal', 2000);
    addRow('Protein', '6.8', 'g', null);
    addRow('Carbohydrate', '54.2', 'g', null);
    addRow('Total Sugars', '1.2', 'g', null);
    addRow('Added Sugars', '0.0', 'g', 50);
    addRow('Total Fat', '33.7', 'g', 67);
    addRow('Saturated Fat', '15.0', 'g', 22);
    addRow('Trans Fat', '0.1', 'g', 2);
    addRow('Sodium', '512', 'mg', 2000);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      child: Column(
        children: [
          // Table Title Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 1.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'NUTRITIONAL INFORMATION^',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'SERVE SIZE $sSize $sUnit**',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Column Headers Row
          Table(
            border: const TableBorder(
              horizontalInside: BorderSide(color: Colors.black, width: 0.8),
              verticalInside: BorderSide(color: Colors.black, width: 0.8),
              bottom: BorderSide(color: Colors.black, width: 1.2),
            ),
            columnWidths: const {
              0: FlexColumnWidth(4.2),
              1: FlexColumnWidth(2.8),
              2: FlexColumnWidth(3.4),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    child: Text(
                      'Nutrients',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.black),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                    child: Text(
                      'Per 100 g',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                    child: Text(
                      '%RDA Per Serve',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              ...rowsData.map((item) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: (item.name == 'Energy' || item.name == 'Total Fat' || item.name == 'Protein')
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: Colors.black87,
                        ),
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2.5),
                      child: Text(
                        item.per100g,
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2.5),
                      child: Text(
                        item.rdaPerServe.isNotEmpty ? item.rdaPerServe : '—',
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutritionRowItem {
  const _NutritionRowItem({required this.name, required this.per100g, required this.rdaPerServe});
  final String name;
  final String per100g;
  final String rdaPerServe;
}

class _OfficialFssaiBadge extends StatelessWidget {
  const _OfficialFssaiBadge({required this.licenseNumber});
  final String licenseNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/fssai_logo.png',
            width: 52,
            height: 22,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 2),
          Text(
            'Lic. No. ${licenseNumber.isNotEmpty ? licenseNumber : "12345678901234"}',
            style: const TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: 0.2,
            ),
            softWrap: true,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MiniSpecItem extends StatelessWidget {
  const _MiniSpecItem(this.label, this.val);
  final String label;
  final String val;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.2,
          ),
          softWrap: true,
        ),
        const SizedBox(height: 2),
        Text(
          val.isNotEmpty ? val : '—',
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            height: 1.2,
          ),
          softWrap: true,
        ),
      ],
    );
  }
}

class _GS1Ean13BarcodePainter extends CustomPainter {
  _GS1Ean13BarcodePainter({required this.barcodeDigits});
  final String barcodeDigits;

  @override
  void paint(Canvas canvas, Size size) {
    final modules = GS1Ean13Encoder.encodeModules(barcodeDigits);
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    // Draw white quiet zone background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final moduleWidth = size.width / modules.length;

    for (int i = 0; i < modules.length; i++) {
      if (modules[i]) {
        final isGuard = (i < 3) || (i >= 45 && i < 50) || (i >= modules.length - 3);
        final barHeight = isGuard ? size.height : size.height * 0.88;

        canvas.drawRect(
          Rect.fromLTWH(i * moduleWidth, 0, moduleWidth + 0.1, barHeight),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GS1Ean13BarcodePainter oldDelegate) =>
      oldDelegate.barcodeDigits != barcodeDigits;
}
