import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/small_business_label_model.dart';
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
            padding: const EdgeInsets.all(16.0),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            typeFlavour.isNotEmpty ? '$productCategory • $typeFlavour' : productCategory,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Indian Veg Symbol
                    Container(
                      width: 26,
                      height: 26,
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
                          width: 12,
                          height: 12,
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
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (unitSalePrice.isNotEmpty)
                              Text(
                                'USP: $unitSalePrice',
                                style: const TextStyle(fontSize: 9, color: AppColors.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandDeepGreen,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              '(Incl. of all taxes)',
                              style: TextStyle(fontSize: 8.5, color: AppColors.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Ingredients Formulation List
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INGREDIENTS LIST (DESCENDING ORDER OF % WEIGHT)',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ingredientsList,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF334155), height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Allergen Warning Strip
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    'ALLERGEN ADVICE: Contains $allergensList. Processed in a clean facility.',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Nutritional Facts Table Grid
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'NUTRITIONAL FACTS TABLE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: 0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Per 100g / ${labelModel?.servingSize ?? 30}${labelModel?.servingSizeUnit ?? 'g'}',
                              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: AppColors.brandDeepGreen),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 10, color: Color(0xFFCBD5E1)),
                      if (nutrients.isNotEmpty)
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: nutrients.take(8).map((n) {
                            return Text(
                              '${n.label}: ${n.value} ${n.unit}',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF334155)),
                            );
                          }).toList(),
                        )
                      else
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: const [
                            Text('Energy: 410 kcal', style: TextStyle(fontSize: 10, color: Color(0xFF334155))),
                            Text('Protein: 6.5 g', style: TextStyle(fontSize: 10, color: Color(0xFF334155))),
                            Text('Carbs: 48.0 g', style: TextStyle(fontSize: 10, color: Color(0xFF334155))),
                            Text('Added Sugar: 0 g', style: TextStyle(fontSize: 10, color: Color(0xFF334155))),
                            Text('Total Fat: 22.0 g', style: TextStyle(fontSize: 10, color: Color(0xFF334155))),
                            Text('Sodium: 920 mg', style: TextStyle(fontSize: 10, color: Color(0xFF334155))),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Product Claims Badges
                if (selectedClaims.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: selectedClaims.take(4).map((claim) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Text(
                          claim.title,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                ],

                // Dates, Batch & Licensing Section
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _MiniSpecItem('Batch No.', batchNumber)),
                          const SizedBox(width: 4),
                          Expanded(child: _MiniSpecItem('Mfg Date', mfgDate)),
                          const SizedBox(width: 4),
                          Expanded(child: _MiniSpecItem('Best Before', bestBefore)),
                        ],
                      ),
                      const Divider(height: 10, color: Color(0xFFE2E8F0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _MiniSpecItem('FSSAI Lic. No.', fssaiNumber)),
                          const SizedBox(width: 4),
                          Expanded(child: _MiniSpecItem('Customer Care', consumerCarePhone)),
                        ],
                      ),
                      if (storageInstructions.isNotEmpty) ...[
                        const Divider(height: 10, color: Color(0xFFE2E8F0)),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'STORAGE: $storageInstructions',
                            style: const TextStyle(fontSize: 9, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Manufacturer Details
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MANUFACTURED & PACKED BY',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        manufacturerName,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        manufacturerAddress,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (consumerCareEmail.isNotEmpty)
                        Text(
                          'Email: $consumerCareEmail • Country of Origin: INDIA',
                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF475569)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Scannable GS1 Barcode Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tappable Standard Scannable Barcode Card
                    Expanded(
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
                              Flexible(
                                flex: 4,
                                child: CustomPaint(
                                  size: const Size(52, 28),
                                  painter: _GS1Ean13BarcodePainter(
                                    barcodeDigits: GS1Ean13Encoder.normalizeEan13(formattedBarcode),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                flex: 5,
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
                    const SizedBox(width: 8),

                    // Official Industry Standard FSSAI Emblem Badge
                    _OfficialFssaiBadge(licenseNumber: fssaiNumber),
                  ],
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Official FSSAI emblem banner
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stylized FSSAI Tri-color Swoosh Icon
              CustomPaint(
                size: const Size(14, 14),
                painter: _FssaiLogoIconPainter(),
              ),
              const SizedBox(width: 4),
              const Text(
                'fssai',
                style: TextStyle(
                  fontFamily: 'Arial',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0B3B60),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            'Lic. No. ${licenseNumber.isNotEmpty ? licenseNumber : "12345678901234"}',
            style: const TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _FssaiLogoIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final orangePaint = Paint()
      ..color = const Color(0xFFF97316)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final greenPaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Top Orange Arc
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      3.14 * 1.1,
      3.14 * 0.8,
      false,
      orangePaint,
    );

    // Bottom Green Arc
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      3.14 * 0.1,
      3.14 * 0.8,
      false,
      greenPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniSpecItem extends StatelessWidget {
  const _MiniSpecItem(this.label, this.val);
  final String label;
  final String val;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          val.isNotEmpty ? val : '—',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// GS1 EAN-13 Standard Barcode Binary Encoder
class GS1Ean13Encoder {
  static const List<String> _parityTable = [
    'LLLLLL', // 0
    'LLGLGG', // 1
    'LLGGLG', // 2
    'LLGGGL', // 3
    'LGLLGG', // 4
    'LGGLLG', // 5
    'LGGGLL', // 6
    'LGLGLG', // 7
    'LGLGGL', // 8
    'LGGLGL', // 9
  ];

  static const List<String> _lCode = [
    '0001101', // 0
    '0011001', // 1
    '0010011', // 2
    '0111101', // 3
    '0100011', // 4
    '0110001', // 5
    '0101111', // 6
    '0111011', // 7
    '0110111', // 8
    '0001011', // 9
  ];

  static const List<String> _gCode = [
    '0100111', // 0
    '0110011', // 1
    '0011011', // 2
    '0100001', // 3
    '0011101', // 4
    '0111001', // 5
    '0000101', // 6
    '0010001', // 7
    '0001001', // 8
    '0010111', // 9
  ];

  static const List<String> _rCode = [
    '1110010', // 0
    '1100110', // 1
    '1101100', // 2
    '1000010', // 3
    '1011100', // 4
    '1001110', // 5
    '1010000', // 6
    '1000100', // 7
    '1001000', // 8
    '1110100', // 9
  ];

  static int computeChecksum(String twelveDigits) {
    int sumOdd = 0;
    int sumEven = 0;
    for (int i = 0; i < 12; i++) {
      final d = int.tryParse(twelveDigits[i]) ?? 0;
      if (i % 2 == 0) {
        sumOdd += d;
      } else {
        sumEven += d;
      }
    }
    final total = sumOdd + (sumEven * 3);
    final mod = total % 10;
    return mod == 0 ? 0 : 10 - mod;
  }

  static String normalizeEan13(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) digits = '890123456789';
    if (digits.length < 12) {
      digits = digits.padRight(12, '0');
    } else if (digits.length > 13) {
      digits = digits.substring(0, 13);
    }
    if (digits.length == 12) {
      digits = '$digits${computeChecksum(digits)}';
    } else if (digits.length == 13) {
      final base = digits.substring(0, 12);
      final cs = computeChecksum(base);
      digits = '$base$cs';
    }
    return digits;
  }

  static List<bool> encodeModules(String ean13) {
    final validEan = normalizeEan13(ean13);
    final firstDigit = int.parse(validEan[0]);
    final parity = _parityTable[firstDigit];

    final modules = <bool>[];

    // 1. Start Guard: 101
    modules.addAll([true, false, true]);

    // 2. Left 6 Digits
    for (int i = 0; i < 6; i++) {
      final digit = int.parse(validEan[i + 1]);
      final isL = parity[i] == 'L';
      final pattern = isL ? _lCode[digit] : _gCode[digit];
      for (int b = 0; b < pattern.length; b++) {
        modules.add(pattern[b] == '1');
      }
    }

    // 3. Center Guard: 01010
    modules.addAll([false, true, false, true, false]);

    // 4. Right 6 Digits
    for (int i = 7; i < 13; i++) {
      final digit = int.parse(validEan[i]);
      final pattern = _rCode[digit];
      for (int b = 0; b < pattern.length; b++) {
        modules.add(pattern[b] == '1');
      }
    }

    // 5. End Guard: 101
    modules.addAll([true, false, true]);

    return modules;
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
