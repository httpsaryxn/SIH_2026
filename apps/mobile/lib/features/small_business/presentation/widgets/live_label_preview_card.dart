import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'claim_item_card.dart';

class LiveLabelPreviewCard extends StatelessWidget {
  const LiveLabelPreviewCard({
    super.key,
    this.brandName = 'Desi Harvest',
    this.productName = 'Authentic Mango Pickle',
    this.productCategory = 'Pickles & Condiments',
    this.netQuantity = '250 g',
    this.mrp = '₹ 149.00',
    this.unitSalePrice = '₹ 0.60 / g',
    this.batchNumber = 'DH-2026-B8',
    this.mfgDate = 'AUG 2026',
    this.bestBefore = '12 MONTHS from Packaging',
    this.fssaiNumber = '12345678901234',
    this.manufacturerName = 'Desi Harvest Foods Pvt. Ltd.',
    this.manufacturerAddress = 'Plot 12, Greenfield Organic Estate, Phase 3, Pune, MH, 411028',
    this.consumerCarePhone = '+91 98765 43210',
    this.consumerCareEmail = 'care@desiharvest.in',
    this.selectedClaims = const [],
    this.isVegetarian = true,
  });

  final String brandName;
  final String productName;
  final String productCategory;
  final String netQuantity;
  final String mrp;
  final String unitSalePrice;
  final String batchNumber;
  final String mfgDate;
  final String bestBefore;
  final String fssaiNumber;
  final String manufacturerName;
  final String manufacturerAddress;
  final String consumerCarePhone;
  final String consumerCareEmail;
  final List<ProductClaim> selectedClaims;
  final bool isVegetarian;

  @override
  Widget build(BuildContext context) {
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
                Row(
                  children: const [
                    Icon(
                      Icons.aspect_ratio_rounded,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'PACKAGED COMMODITY LABEL PREVIEW',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PRINT SCALE 1:1',
                    style: TextStyle(
                      color: Color(0xFF047857),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Label Content Canvas
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Header Row with Veg Mark
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            brandName.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            productName,
                            style: const TextStyle(
                              color: Color(0xFF004B1E),
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            productCategory,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Indian Green Vegetarian Symbol (Square box with green dot)
                    if (isVegetarian)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF16A34A),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Selected Product Claims Badges
                if (selectedClaims.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: selectedClaims.map((claim) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF86EFAC),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          claim.title,
                          style: const TextStyle(
                            color: Color(0xFF15803D),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Ingredients Box
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
                    children: const [
                      Text(
                        'INGREDIENTS:',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Raw Mango Pieces (65%), Cold Pressed Mustard Oil, Iodized Salt, Red Chilli Powder, Fenugreek Seeds, Mustard Seeds, Turmeric Powder, Asafoetida (Hing).',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          color: Color(0xFF334155),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ALLERGEN DECLARATION: CONTAINS MUSTARD. PROCESSED IN A FACILITY HANDLING SESAME AND NUTS.',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF80253D),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Nutritional Values Table (Indian FSSAI Standard)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        color: const Color(0xFF004B1E),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'NUTRITIONAL FACTS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Per 100g / Serving (30g)',
                              style: TextStyle(
                                color: Color(0xFFDAE2FD),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _NutrientRow('Energy / Calories', '250 kcal', '75 kcal'),
                      _NutrientRow('Protein', '2.1 g', '0.6 g'),
                      _NutrientRow('Carbohydrates', '14.5 g', '4.3 g'),
                      _NutrientRow('  - Total Sugars', '4.2 g', '1.2 g', isSub: true),
                      _NutrientRow('  - Added Sugars', '0.0 g', '0.0 g', isSub: true),
                      _NutrientRow('Total Fat', '18.0 g', '5.4 g'),
                      _NutrientRow('  - Saturated Fat', '2.5 g', '0.7 g', isSub: true),
                      _NutrientRow('  - Trans Fat', '0.0 g', '0.0 g', isSub: true),
                      _NutrientRow('Sodium', '890 mg', '267 mg', isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Legal Metrology Declarations (Net Qty, MRP, USP, Batch, Dates)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _DeclarationPill('NET QUANTITY', netQuantity),
                          _DeclarationPill('MRP (INCL. TAXES)', mrp),
                          _DeclarationPill('UNIT SALE PRICE', unitSalePrice),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _DeclarationPill('BATCH NO.', batchNumber),
                          _DeclarationPill('MFG DATE', mfgDate),
                          _DeclarationPill('BEST BEFORE', bestBefore),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Manufacturer, FSSAI & Consumer Care
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FSSAI Badge & Logo
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF005AC2).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF005AC2).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'fssai',
                              style: TextStyle(
                                color: Color(0xFF005AC2),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            Text(
                              fssaiNumber,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Address & Care
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MFD. & PKGD. BY: $manufacturerName',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              manufacturerAddress,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'CONSUMER CARE: $consumerCarePhone | $consumerCareEmail',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Barcode & QR Code Mock Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Barcode graphic mock
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.qr_code_2_rounded,
                            size: 32,
                            color: Color(0xFF0F172A),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '|||||| | |||||| || |',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                '8 901234 567890',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Country of Origin
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text(
                            'COUNTRY OF ORIGIN',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            'INDIA (BHARAT)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
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
}

class _NutrientRow extends StatelessWidget {
  const _NutrientRow(
    this.nutrient,
    this.per100g,
    this.perServing, {
    this.isSub = false,
    this.isLast = false,
  });

  final String nutrient;
  final String per100g;
  final String perServing;
  final bool isSub;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: isSub ? const Color(0xFFF8FAFC) : Colors.white,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            nutrient,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSub ? FontWeight.w500 : FontWeight.w700,
              color: isSub ? const Color(0xFF475569) : const Color(0xFF0F172A),
            ),
          ),
          Row(
            children: [
              Text(
                per100g,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                perServing,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeclarationPill extends StatelessWidget {
  const _DeclarationPill(this.title, this.value);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
