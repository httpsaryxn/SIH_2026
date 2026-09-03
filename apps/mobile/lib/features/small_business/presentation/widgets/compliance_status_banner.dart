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

enum HealthQualityGrade { gradeA, gradeB, gradeC, gradeD }

class NutritionalHealthReport {
  const NutritionalHealthReport({
    required this.overallHealthGrade,
    required this.healthSummary,
    required this.healthPills,
    required this.hfssWarnings,
    required this.isUltraProcessed,
  });

  final HealthQualityGrade overallHealthGrade;
  final String healthSummary;
  final List<String> healthPills;
  final List<String> hfssWarnings;
  final bool isUltraProcessed;
}

class ComplianceStatusBanner extends StatelessWidget {
  const ComplianceStatusBanner({
    super.key,
    this.score = 98,
    this.labelModel,
  });

  final int score;
  final SmallBusinessLabelModel? labelModel;

  static NutritionalHealthReport analyzeNutritionalQuality(SmallBusinessLabelModel? model) {
    if (model == null) {
      return const NutritionalHealthReport(
        overallHealthGrade: HealthQualityGrade.gradeA,
        healthSummary: 'Nutrient-Dense Formulation (Clean Label)',
        healthPills: ['Zero Trans Fat ✓', 'Natural Ingredients ✓', 'Optimal Sodium ✓'],
        hfssWarnings: [],
        isUltraProcessed: false,
      );
    }

    final healthPills = <String>[];
    final hfssWarnings = <String>[];

    // 1. Analyze Added Sugars & Total Sugars
    double addedSugars = 0;
    double totalSugars = 0;
    double energy = 0;
    double totalFat = 0;
    double saturatedFat = 0;
    double transFat = 0;
    double sodium = 0;
    double protein = 0;

    for (final n in model.nutrients) {
      final labelLower = n.label.toLowerCase();
      final val = double.tryParse(n.value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      if (labelLower.contains('added sugar')) {
        addedSugars = val;
      } else if (labelLower.contains('sugar')) {
        totalSugars = val;
      } else if (labelLower.contains('energy') || labelLower.contains('calorie')) {
        energy = val;
      } else if (labelLower.contains('sat') && labelLower.contains('fat')) {
        saturatedFat = val;
      } else if (labelLower.contains('trans') && labelLower.contains('fat')) {
        transFat = val;
      } else if (labelLower.contains('total fat') || labelLower == 'fat') {
        totalFat = val;
      } else if (labelLower.contains('sodium')) {
        sodium = val;
      } else if (labelLower.contains('protein')) {
        protein = val;
      }
    }

    // Sugar checks (HFSS regulation: Added sugar > 10% total energy or > 25g/100g)
    if (addedSugars > 25 || (energy > 0 && (addedSugars * 4 / energy) > 0.10)) {
      hfssWarnings.add('HFSS Alert: High Added Sugar (${addedSugars.toStringAsFixed(1)}g)');
    } else if (addedSugars == 0 && model.nutrients.isNotEmpty) {
      healthPills.add('Zero Added Sugar ✓');
    } else if (totalSugars > 0 && totalSugars <= 5) {
      healthPills.add('Low Total Sugar (${totalSugars.toStringAsFixed(1)}g) ✓');
    }

    // Sodium checks (HFSS regulation: Sodium > 1000mg per 100g)
    if (sodium > 1000) {
      hfssWarnings.add('HFSS Alert: High Sodium (${sodium.toInt()}mg)');
    } else if (sodium < 140 && sodium > 0) {
      healthPills.add('Low Sodium Formulation ✓');
    }

    // Fat & Trans Fat checks
    if (transFat > 0.2) {
      hfssWarnings.add('Critical: Trans Fat Non-Compliant (${transFat.toStringAsFixed(1)}g)');
    } else if (model.nutrients.isNotEmpty) {
      healthPills.add('Zero Trans Fat ✓');
    }

    if (saturatedFat > 6) {
      hfssWarnings.add('High Saturated Fat Notice (${saturatedFat.toStringAsFixed(1)}g)');
    } else if (saturatedFat > 0 && saturatedFat <= 3) {
      healthPills.add('Low Saturated Fat ✓');
    }

    if (totalFat > 0 && totalFat <= 3) {
      healthPills.add('Low Fat (${totalFat.toStringAsFixed(1)}g) ✓');
    }

    // Protein & Functional Nutrients
    if (protein >= 6) {
      healthPills.add('High Protein (${protein.toStringAsFixed(1)}g) ✓');
    }

    // 2. Analyze Ingredients Cleanliness
    bool hasArtificialAdditives = false;
    final allIngredientsText = model.ingredients.map((i) => i.name.toLowerCase()).join(' ');

    if (allIngredientsText.contains('e621') ||
        allIngredientsText.contains('msg') ||
        allIngredientsText.contains('aspartame') ||
        allIngredientsText.contains('tartrazine') ||
        allIngredientsText.contains('synthetic color') ||
        allIngredientsText.contains('preservative class ii') ||
        allIngredientsText.contains('bha') ||
        allIngredientsText.contains('bht')) {
      hasArtificialAdditives = true;
      hfssWarnings.add('Synthetic Additives / Colors Declared');
    } else if (model.ingredients.isNotEmpty) {
      healthPills.add('100% Traditional Formulation ✓');
    }

    // Calculate Grade
    HealthQualityGrade grade = HealthQualityGrade.gradeA;
    String summary = 'Clean Formulation (High Nutritional Quality)';

    if (hfssWarnings.length >= 2 || transFat > 0.2) {
      grade = HealthQualityGrade.gradeD;
      summary = 'HFSS High Salt/Sugar Alert - Action Advised';
    } else if (hfssWarnings.length == 1) {
      grade = HealthQualityGrade.gradeC;
      summary = 'Moderate Nutrition Profile (${hfssWarnings.first})';
    } else if (healthPills.length >= 2) {
      grade = HealthQualityGrade.gradeA;
      summary = 'Nutrient-Dense & Clean Label Certified';
    } else {
      grade = HealthQualityGrade.gradeB;
      summary = 'Standard Compliant Food Profile';
    }

    return NutritionalHealthReport(
      overallHealthGrade: grade,
      healthSummary: summary,
      healthPills: healthPills,
      hfssWarnings: hfssWarnings,
      isUltraProcessed: hasArtificialAdditives,
    );
  }

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

  static int calculateScore(List<AuditCheckItem> checks, NutritionalHealthReport healthReport) {
    int total = 0;
    for (final c in checks) {
      if (c.isPassed) total += c.weight;
    }
    // Adjust score based on HFSS warnings
    if (healthReport.hfssWarnings.isNotEmpty) {
      total -= (healthReport.hfssWarnings.length * 8);
    }
    return total.clamp(20, 100);
  }

  @override
  Widget build(BuildContext context) {
    final healthReport = analyzeNutritionalQuality(labelModel);
    final checks = evaluateCompliance(labelModel);
    final dynamicScore = labelModel != null ? calculateScore(checks, healthReport) : score;

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
                          Text(
                            healthReport.healthSummary,
                            style: const TextStyle(
                              color: Color(0xFFDAE2FD),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
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
          
          // HFSS Warning Alerts if present
          if (healthReport.hfssWarnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF87171)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: healthReport.hfssWarnings.map((w) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            w,
                            style: const TextStyle(
                              color: Color(0xFF991B1B),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white24),
          const SizedBox(height: 10),

          // Dynamic Nutritional Health Quality Pills
          if (healthReport.healthPills.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: healthReport.healthPills.map((hp) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF86EFAC).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF86EFAC), width: 0.8),
                  ),
                  child: Text(
                    hp,
                    style: const TextStyle(
                      color: Color(0xFFDCFCE7),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],

          // Regulatory checkpoint badges
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
