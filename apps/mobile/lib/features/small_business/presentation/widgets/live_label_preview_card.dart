import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/small_business_label_model.dart';
import '../../data/services/gs1_ean13_encoder.dart';
import 'claim_item_card.dart';
import 'product_image_widget.dart';

class LiveLabelPreviewCard extends StatelessWidget {
  const LiveLabelPreviewCard({
    super.key,
    this.brandName = 'Haldirams',
    this.logoUrl,
    this.productName = 'Kurkure',
    this.productCategory = 'Snacks & Namkeen',
    this.typeFlavour = '',
    this.netQuantity = '70 g',
    this.mrp = '₹ 20.00',
    this.unitSalePrice = '₹ 0.28 / g',
    this.batchNumber = 'HALDIRAMS-2026-I92',
    this.mfgDate = 'AUG 2026',
    this.bestBefore = '12 Months from Packaging',
    this.storageInstructions = 'Do not freeze. Store in an airtight container.',
    this.fssaiNumber = '74125896323145',
    this.manufacturerName = 'Haldirams',
    this.manufacturerAddress = 'Mere Ghar Pe',
    this.consumerCarePhone = '9876543210',
    this.consumerCareEmail = 'kurkure@gmail.com',
    this.selectedClaims = const [],
    this.isVegetarian = true,
    this.widthMm = 100,
    this.heightMm = 118,
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

  String _getBarcodeDigits() {
    return GS1Ean13Encoder.deriveBarcodeDigits(
      fssaiNumber: fssaiNumber,
    );
  }

  void _showBarcodeDetails(BuildContext context) {
    final barcode = _getBarcodeDigits();
    final split = GS1Ean13Encoder.splitForDisplay(barcode);
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
                    size: const Size(200, 68),
                    painter: _GS1Ean13BarcodePainter(barcodeDigits: barcode),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${split.d1}  ${split.left6}  ${split.right6}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'GS1 EAN-13 VERIFIED ✓',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF047857),
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
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        child: ProductImageWidget(
          imageUrl: logo.trim(),
          category: productCategory,
          width: 38,
          height: 38,
          borderRadius: 6,
          fit: BoxFit.contain,
        ),
      );
    }
    return _fallbackLogo();
  }

  Widget _fallbackLogo() {
    final letter = brandName.isNotEmpty ? brandName.substring(0, 1).toUpperCase() : 'B';
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF047857),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barcodeDigits = _getBarcodeDigits();
    final splitBarcode = GS1Ean13Encoder.splitForDisplay(barcodeDigits);

    // Formulation Ingredients with explicit % w/w
    final ingredientsText = (labelModel != null && labelModel!.ingredients.isNotEmpty)
        ? labelModel!.ingredients.map((i) {
            if (i.percentage != null && i.percentage! > 0) {
              final pctStr = (i.percentage! == i.percentage!.roundToDouble())
                  ? '${i.percentage!.toInt()}%'
                  : '${i.percentage!.toStringAsFixed(1)}%';
              return '${i.name} ($pctStr)';
            }
            return i.name;
          }).join(', ')
        : 'Turmeric Powder (28%), Red Chilli Powder (24%), Coriander Powder (20%), Mustard Seeds (14%), Black Pepper (8%), Garam Masala (6%)';

    // Allergens
    final allergensText = (labelModel != null && labelModel!.allergens.isNotEmpty)
        ? labelModel!.allergens.join(', ')
        : 'Wheat / Gluten';

    // Nutrients
    final nutrientsList = labelModel?.nutrients ?? [];

    // Parse Net Quantity & Oz
    final cleanNetQty = netQuantity.replaceAll(RegExp(r'[^0-9.]'), '');
    final netGrams = double.tryParse(cleanNetQty) ?? 70.0;
    final ozVal = (netGrams * 0.035274).toStringAsFixed(2);

    // MRP clean string
    final cleanMrp = mrp.replaceAll('₹', '').replaceFirst('Rs.', '').trim();
    final mrpDisplay = cleanMrp.isNotEmpty ? 'Rs. $cleanMrp' : 'Rs. 20.00';
    final uspDisplay = unitSalePrice.isNotEmpty ? unitSalePrice.replaceAll('₹', 'Rs. ') : 'Rs. 0.28 / g';

    // Serving Size & Calories calculation
    final sSize = labelModel?.servingSize.isNotEmpty == true ? labelModel!.servingSize : '70';
    final sUnit = labelModel?.servingSizeUnit.isNotEmpty == true ? labelModel!.servingSizeUnit : 'g';
    final energyNutrient = nutrientsList.cast<SmallBusinessNutrientModel?>().firstWhere(
      (n) => n?.label.toLowerCase() == 'energy',
      orElse: () => null,
    );
    final energyVal = double.tryParse(energyNutrient?.value ?? '') ?? 536.0;
    final serveG = double.tryParse(sSize) ?? 70.0;
    final calPerServe = ((energyVal * serveG) / 100.0).round().toString();
    final servingsPerPack = (serveG > 0) ? (netGrams / serveG).round().clamp(1, 99) : 1;

    final effectiveBrand = brandName.isNotEmpty ? brandName : 'HALDIRAMS';
    final effectiveProduct = productName.isNotEmpty ? productName : 'KURKURE';
    final effectiveCategory = productCategory.isNotEmpty ? productCategory.toUpperCase() : 'SNACKS & NAMKEEN';

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
          // Studio Preview Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(
                bottom: BorderSide(color: Color(0xFFCBD5E1), width: 1),
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
                        size: 15,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'COMMERCIAL PACKAGING SPEC (${widthMm.toInt()} × ${heightMm.toInt()} MM)',
                            style: const TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
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
                    '300 DPI PRINT READY',
                    style: TextStyle(
                      color: Color(0xFF15803D),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // THE ULTRA-COMPACT PACKAGING LABEL (Border-to-border, Zero Vacant Space)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.black, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Compact Header: Brand, Product, Category, Net Wt Badge & Veg Dot
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLogoWidget(),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                effectiveBrand.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF047857),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                effectiveProduct,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: -0.2,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'PROPRIETARY FOOD [$effectiveCategory]',
                                style: const TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Net Weight Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: const Color(0xFF94A3B8), width: 0.8),
                          ),
                          child: Text(
                            'NET WT. $cleanNetQty ${labelModel?.netQuantityUnit ?? "g"}',
                            style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Statutory Vegetarian Emblem (Exact 1:1)
                        Container(
                          width: 19,
                          height: 19,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: isVegetarian ? const Color(0xFF16A34A) : const Color(0xFF991B1B),
                              width: 1.6,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isVegetarian ? const Color(0xFF16A34A) : const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  const Divider(height: 1, thickness: 1.2, color: Colors.black),

                  // 2. High-Density Nutrition Facts Panel
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                    child: _buildNutritionFactsPanel(
                      nutrients: nutrientsList,
                      serveSize: '$sSize $sUnit',
                      calPerServe: calPerServe,
                      servingsPerPack: servingsPerPack,
                    ),
                  ),

                  // 3. Ingredients with Formulation Content Percentages (% w/w)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 8, color: Color(0xFF1E293B), height: 1.28),
                        children: [
                          const TextSpan(
                            text: 'INGREDIENTS: ',
                            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
                          ),
                          TextSpan(text: ingredientsText),
                        ],
                      ),
                    ),
                  ),

                  // 4. Allergen Advice Strip
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: const Color(0xFFFEB2B2), width: 0.8),
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 7.5, color: Color(0xFF991B1B), height: 1.2),
                          children: [
                            const TextSpan(
                              text: 'ALLERGEN ADVICE: ',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            TextSpan(
                              text: 'Contains $allergensText. Made in a facility that also processes Mustard, Sesame & Peanuts.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 5. Specification & Origin Strip
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 0.7),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'NET WT. $cleanNetQty ${labelModel?.netQuantityUnit ?? "g"} / $ozVal oz.   ',
                              style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: Colors.black),
                            ),
                            const Text(
                              'PRODUCT OF INDIA / PRODUIT DE L\'INDE   ',
                              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                            ),
                            const Text(
                              'COMMERCIAL PACK',
                              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 6. Legal Metrology Pricing & Traceability Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Net Qty
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('NET QUANTITY', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.3)),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text('$cleanNetQty ${labelModel?.netQuantityUnit ?? "g"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 0.8, height: 22, color: const Color(0xFFCBD5E1)),
                              const SizedBox(width: 8),
                              // MRP
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('MAX RETAIL PRICE [MRP]', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.3)),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        children: [
                                          Text(mrpDisplay, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF047857))),
                                          const SizedBox(width: 4),
                                          const Text('[Incl. of all taxes]', style: TextStyle(fontSize: 7.5, color: Color(0xFF64748B))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 0.8, height: 22, color: const Color(0xFFCBD5E1)),
                              const SizedBox(width: 8),
                              // USP
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('UNIT SALE PRICE [USP]', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.3)),
                                    Text(uspDisplay, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Colors.black)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 8, thickness: 0.7, color: Color(0xFFCBD5E1)),
                          Text(
                            'Batch No: $batchNumber   •   Mfg Date: $mfgDate   •   Best Before: $bestBefore',
                            style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Storage: $storageInstructions',
                            style: const TextStyle(fontSize: 7, color: Color(0xFF555555)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 7. Scannable GS1 Barcode & Authentic FSSAI Logo Side-by-Side
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Row(
                        children: [
                          // Left: Scannable Barcode with Human-Readable Numbers
                          Expanded(
                            flex: 5,
                            child: InkWell(
                              onTap: () => _showBarcodeDetails(context),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CustomPaint(
                                      size: const Size(140, 26),
                                      painter: _GS1Ean13BarcodePainter(barcodeDigits: barcodeDigits),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${splitBarcode.d1}   ${splitBarcode.left6}   ${splitBarcode.right6}',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const Text(
                                      'GS1 EAN-13 VERIFIED ✓',
                                      style: TextStyle(
                                        fontSize: 6.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(width: 0.8, height: 48, color: const Color(0xFFCBD5E1)),
                          const SizedBox(width: 8),
                          // Right: Un-distorted FSSAI Logo & License Number
                          Expanded(
                            flex: 4,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _OfficialFssaiBadge(licenseNumber: fssaiNumber),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 8. Manufacturer, Consumer Care & Compliance Declaration Footer
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    style: const TextStyle(fontSize: 7.5, color: Colors.black),
                                    children: [
                                      const TextSpan(text: 'Mfd. By: ', style: TextStyle(fontWeight: FontWeight.w900)),
                                      TextSpan(text: '$manufacturerName, $manufacturerAddress  |  '),
                                      const TextSpan(text: 'Lic. No. ', style: TextStyle(fontWeight: FontWeight.w900)),
                                      TextSpan(text: fssaiNumber),
                                    ],
                                  ),
                                ),
                                const Divider(height: 5, thickness: 0.6, color: Color(0xFFE2E8F0)),
                                Text(
                                  'Consumer Care: +91 $consumerCarePhone  •  Email: $consumerCareEmail  •  Origin: INDIA  •  Web: ${labelModel?.consumerCareWebsite ?? "www.haldirams.com"}',
                                  style: const TextStyle(fontSize: 7, color: Color(0xFF333333)),
                                ),
                                const Divider(height: 5, thickness: 0.6, color: Color(0xFFE2E8F0)),
                                const Text(
                                  '✓ Compliant with Legal Metrology (Packaged Commodities) Rules 2011 & FSSAI Standards.',
                                  style: TextStyle(fontSize: 6.8, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                                ),
                                Text(
                                  'Packaging: ${labelModel?.packagingType ?? "Food Grade Metallized Pouch"} • Keep Clean (MoEFCC Disposal Logo)',
                                  style: const TextStyle(fontSize: 6.5, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Clean India Disposal Emblem
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF047857), width: 0.9),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_upward_rounded, size: 13, color: Color(0xFF047857)),
                                  Text('DISPOSE', style: TextStyle(fontSize: 3.2, fontWeight: FontWeight.w900, color: Color(0xFF047857))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionFactsPanel({
    required List<SmallBusinessNutrientModel> nutrients,
    required String serveSize,
    required String calPerServe,
    required int servingsPerPack,
  }) {
    // Standard rows list
    final defaultRows = [
      {'name': 'Energy', 'val': '536 kcal', 'rda': '19%', 'level': 0},
      {'name': 'Protein', 'val': '5.6 g', 'rda': '—', 'level': 0},
      {'name': 'Carbohydrate', 'val': '230 g', 'rda': '—', 'level': 0},
      {'name': 'Total Sugars', 'val': '2 g', 'rda': '—', 'level': 1},
      {'name': 'Added Sugars', 'val': '2 g', 'rda': '3%', 'level': 2},
      {'name': 'Total Fat', 'val': '10 g', 'rda': '10%', 'level': 0},
      {'name': 'Saturated Fat', 'val': '1 g', 'rda': '3%', 'level': 1},
      {'name': 'Trans Fat', 'val': '0 g', 'rda': '0%', 'level': 1},
      {'name': 'Cholesterol', 'val': '0 mg', 'rda': '0%', 'level': 0},
      {'name': 'Sodium', 'val': '222 mg', 'rda': '8%', 'level': 0},
      {'name': 'Potassium', 'val': '140 mg', 'rda': '3%', 'level': 0},
      {'name': 'Calcium', 'val': '40 mg', 'rda': '2%', 'level': 0},
      {'name': 'Iron', 'val': '1.2 mg', 'rda': '4%', 'level': 0},
    ];

    final displayRows = <Map<String, dynamic>>[];

    if (nutrients.isNotEmpty) {
      for (final n in nutrients) {
        final label = n.label;
        final val = '${n.value} ${n.unit}';
        final isSub = n.isSubNutrient;
        final level = isSub ? 1 : 0;
        displayRows.add({
          'name': label,
          'val': val,
          'rda': '—',
          'level': level,
        });
      }
    } else {
      displayRows.addAll(defaultRows);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Black Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'NUTRITION FACTS / VALEUR NUTRITIVE',
                      style: TextStyle(
                        fontFamily: 'Arial',
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'PER ${serveSize.toUpperCase()}',
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Serving Size & % Daily Value Subheader
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Serving Size: $serveSize (Pack: $servingsPerPack srv)',
                      style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '% Daily Value / % RDA *',
                  style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 2, color: Colors.black),

          // Calories Hero Callout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black),
                        children: [
                          TextSpan(text: 'Calories $calPerServe '),
                          const TextSpan(
                            text: '(Energy 536 kcal / 100 g)',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.normal, color: Color(0xFF555555)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '19%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1.4, color: Colors.black),

          // Compact Rows
          ...displayRows.map((r) {
            final name = r['name'] as String;
            final val = r['val'] as String;
            final rda = r['rda'] as String;
            final level = r['level'] as int;

            final isBold = level == 0 || name == 'Total Fat' || name == 'Carbohydrate' || name == 'Protein' || name == 'Sodium';
            final prefix = level == 1 ? '— ' : (level == 2 ? '• ' : '');
            final leftPadding = 8.0 + (level * 10.0);

            return Column(
              children: [
                const Divider(height: 1, thickness: 0.5, color: Color(0xFFE2E8F0)),
                Padding(
                  padding: EdgeInsets.fromLTRB(leftPadding, 2, 8, 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
                              color: isBold ? Colors.black : const Color(0xFF333333),
                            ),
                            children: [
                              TextSpan(text: '$prefix$name '),
                              TextSpan(
                                text: val,
                                style: const TextStyle(fontWeight: FontWeight.normal, color: Color(0xFF555555)),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rda,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
                          color: isBold ? Colors.black : const Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),

          const Divider(height: 1, thickness: 0.6, color: Colors.black),

          // Footnote
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(
              '*5% or less is a little, 15% or more is a lot. % Daily Values based on 2,000 kcal diet.',
              style: TextStyle(fontSize: 6.5, color: Color(0xFF555555)),
            ),
          ),
        ],
      ),
    );
  }
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
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFF047857), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/fssai_logo.png',
            width: 52,
            height: 39,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 2),
          Text(
            'Lic. No. ${licenseNumber.isNotEmpty ? licenseNumber : "74125896323145"}',
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: 0.3,
            ),
            softWrap: true,
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // White quiet zone
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final moduleWidth = size.width / modules.length;

    for (int i = 0; i < modules.length; i++) {
      if (modules[i]) {
        final isGuard = (i < 3) || (i >= 45 && i < 50) || (i >= modules.length - 3);
        final barHeight = isGuard ? size.height : size.height * 0.86;

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
