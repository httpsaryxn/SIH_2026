import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/small_business_label_model.dart';

class AuditCheckItem {
  const AuditCheckItem({
    required this.title,
    required this.isPassed,
    required this.weight,
    this.failureReason,
  });

  final String title;
  final bool isPassed;
  final int weight;
  final String? failureReason;
}

class ComplianceStatusBanner extends StatelessWidget {
  const ComplianceStatusBanner({
    super.key,
    this.score = 98,
    this.labelModel,
  });

  final int score;
  final SmallBusinessLabelModel? labelModel;

  static List<AuditCheckItem> evaluateCompliance(SmallBusinessLabelModel? model) {
    if (model == null) {
      return [
        const AuditCheckItem(title: 'Mandatory Declarations', isPassed: true, weight: 15),
        const AuditCheckItem(title: 'FSSAI Lic. Validated', isPassed: true, weight: 20),
        const AuditCheckItem(title: 'Ingredients List', isPassed: true, weight: 15),
        const AuditCheckItem(title: 'Allergen Bold Warning', isPassed: true, weight: 10),
        const AuditCheckItem(title: 'Nutritional Table', isPassed: true, weight: 15),
        const AuditCheckItem(title: 'MRP & Net Qty', isPassed: true, weight: 15),
        const AuditCheckItem(title: 'Batch & Mfg Dates', isPassed: true, weight: 10),
      ];
    }

    final hasBrandAndProduct = model.brandName.trim().isNotEmpty && model.productName.trim().isNotEmpty;
    final fssaiDigits = model.fssaiLicenseNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final hasValidFssai = fssaiDigits.length == 14;
    final hasIngredients = model.ingredients.isNotEmpty;
    final hasAllergens = model.allergens.isNotEmpty;
    final hasNutrients = model.nutrients.isNotEmpty;
    final hasMrpAndQty = model.mrp.trim().isNotEmpty && model.netQuantity.trim().isNotEmpty;
    final hasBatchAndMfg = model.batchNumber.trim().isNotEmpty && model.mfgDate.trim().isNotEmpty;
    final hasManufacturer = model.manufacturerName.trim().isNotEmpty && model.manufacturerAddress.trim().isNotEmpty;
    final hasCustomerCare = model.consumerCarePhone.trim().isNotEmpty || model.consumerCareEmail.trim().isNotEmpty;

    return [
      AuditCheckItem(
        title: 'Brand & Product Name',
        isPassed: hasBrandAndProduct,
        weight: 10,
        failureReason: hasBrandAndProduct ? null : 'Product name or brand missing',
      ),
      AuditCheckItem(
        title: '14-Digit FSSAI License',
        isPassed: hasValidFssai,
        weight: 15,
        failureReason: hasValidFssai ? null : 'FSSAI License must be 14 digits',
      ),
      AuditCheckItem(
        title: 'Ingredients List (% w/w)',
        isPassed: hasIngredients,
        weight: 15,
        failureReason: hasIngredients ? null : 'Ingredients list not declared',
      ),
      AuditCheckItem(
        title: 'Allergen Bold Warning',
        isPassed: hasAllergens,
        weight: 10,
        failureReason: hasAllergens ? null : 'No allergen advisory declared',
      ),
      AuditCheckItem(
        title: 'Nutritional Facts Table',
        isPassed: hasNutrients,
        weight: 15,
        failureReason: hasNutrients ? null : 'Nutritional values table missing',
      ),
      AuditCheckItem(
        title: 'MRP & Net Quantity',
        isPassed: hasMrpAndQty,
        weight: 10,
        failureReason: hasMrpAndQty ? null : 'MRP or Net Quantity missing',
      ),
      AuditCheckItem(
        title: 'Batch & Mfg / Expiry Dates',
        isPassed: hasBatchAndMfg,
        weight: 10,
        failureReason: hasBatchAndMfg ? null : 'Batch number or Mfg date missing',
      ),
      AuditCheckItem(
        title: 'Manufacturer Facility Address',
        isPassed: hasManufacturer,
        weight: 10,
        failureReason: hasManufacturer ? null : 'Manufacturer address missing',
      ),
      AuditCheckItem(
        title: 'Consumer Care Contact',
        isPassed: hasCustomerCare,
        weight: 5,
        failureReason: hasCustomerCare ? null : 'Helpline phone or email missing',
      ),
    ];
  }

  static int calculateScore(List<AuditCheckItem> checks) {
    int total = 0;
    for (final c in checks) {
      if (c.isPassed) total += c.weight;
    }
    return total.clamp(10, 100);
  }

  @override
  Widget build(BuildContext context) {
    final checks = evaluateCompliance(labelModel);
    final dynamicScore = labelModel != null ? calculateScore(checks) : score;

    final isHigh = dynamicScore >= 85;
    final isMedium = dynamicScore >= 60 && dynamicScore < 85;

    final gradColors = isHigh
        ? [const Color(0xFF004B1E), AppColors.brandDeepGreen]
        : (isMedium
            ? [const Color(0xFF854D0E), const Color(0xFFCA8A04)]
            : [const Color(0xFF991B1B), const Color(0xFFDC2626)]);

    final statusTitle = isHigh
        ? 'Legal Metrology Compliance Passed'
        : (isMedium ? 'Partially Compliant (Action Recommended)' : 'Compliance Action Required');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradColors.last.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isHigh ? Icons.verified_rounded : Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'Real-Time FSSAI & Legal Metrology Audit',
                            style: TextStyle(
                              color: Color(0xFFDAE2FD),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isHigh ? AppColors.primaryFixed : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$dynamicScore%',
                  style: TextStyle(
                    color: isHigh ? const Color(0xFF002109) : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Colors.white24),
          const SizedBox(height: 12),

          // Dynamic checkpoint badges
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: checks.map((c) {
              return _AuditPill(
                text: '${c.title} ${c.isPassed ? '✓' : '⚠'}',
                isPassed: c.isPassed,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AuditPill extends StatelessWidget {
  const _AuditPill({
    required this.text,
    this.isPassed = true,
  });

  final String text;
  final bool isPassed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPassed
            ? Colors.white.withValues(alpha: 0.15)
            : const Color(0xFFFEF08A).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPassed
              ? Colors.white.withValues(alpha: 0.25)
              : const Color(0xFFFEF08A),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isPassed ? Colors.white : const Color(0xFFFEF08A),
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
