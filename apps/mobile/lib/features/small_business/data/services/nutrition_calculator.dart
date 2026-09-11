/// Nutrition & RDA Percentage Calculator for Small Business Labels.
///
/// Implements statutory Recommended Dietary Allowance (RDA) & Daily Value (DV)
/// calculations per FSSAI (Food Safety and Standards Labelling & Display Regulations 2020, Schedule II)
/// and ICMR-NIN 2020 dietary guidelines based on a reference adult diet of 2,000 kcal.
class NutritionCalculator {
  NutritionCalculator._();

  /// Reference Daily Energy Intake for an average adult (2,000 kcal).
  static const double referenceDailyCaloriesKcal = 2000.0;

  /// Internal reference structure holding daily intake amount and canonical unit.
  static const Map<String, _NutrientRef> _rdaTable = {
    // Energy / Calories
    'energy': _NutrientRef(2000.0, 'kcal'),
    'calories': _NutrientRef(2000.0, 'kcal'),

    // Fats & Lipids
    'total fat': _NutrientRef(67.0, 'g'),
    'fat': _NutrientRef(67.0, 'g'),
    'total fats': _NutrientRef(67.0, 'g'),
    'fats': _NutrientRef(67.0, 'g'),
    'lipids': _NutrientRef(67.0, 'g'),
    'saturated fat': _NutrientRef(22.0, 'g'),
    'saturated fatty acids': _NutrientRef(22.0, 'g'),
    'saturated fats': _NutrientRef(22.0, 'g'),
    'sfa': _NutrientRef(22.0, 'g'),
    'trans fat': _NutrientRef(2.0, 'g'),
    'trans fatty acids': _NutrientRef(2.0, 'g'),
    'trans fats': _NutrientRef(2.0, 'g'),
    'tfa': _NutrientRef(2.0, 'g'),
    'cholesterol': _NutrientRef(300.0, 'mg'),
    'monounsaturated fatty acids (mufa)': _NutrientRef(30.0, 'g'),
    'monounsaturated fat': _NutrientRef(30.0, 'g'),
    'mufa': _NutrientRef(30.0, 'g'),
    'polyunsaturated fatty acids (pufa)': _NutrientRef(20.0, 'g'),
    'polyunsaturated fat': _NutrientRef(20.0, 'g'),
    'pufa': _NutrientRef(20.0, 'g'),
    'omega-3 fatty acids': _NutrientRef(2.0, 'g'),
    'omega-3': _NutrientRef(2.0, 'g'),
    'omega-6 fatty acids': _NutrientRef(10.0, 'g'),
    'omega-6': _NutrientRef(10.0, 'g'),

    // Carbohydrates, Fiber & Sugars
    'carbohydrates': _NutrientRef(300.0, 'g'),
    'carbohydrate': _NutrientRef(300.0, 'g'),
    'total carbohydrate': _NutrientRef(300.0, 'g'),
    'total carbohydrates': _NutrientRef(300.0, 'g'),
    'carbs': _NutrientRef(300.0, 'g'),
    'carb': _NutrientRef(300.0, 'g'),
    'dietary fiber': _NutrientRef(30.0, 'g'),
    'dietary fibre': _NutrientRef(30.0, 'g'),
    'fiber': _NutrientRef(30.0, 'g'),
    'fibre': _NutrientRef(30.0, 'g'),
    'crude fiber': _NutrientRef(30.0, 'g'),
    'total sugars': _NutrientRef(50.0, 'g'),
    'total sugar': _NutrientRef(50.0, 'g'),
    'sugars': _NutrientRef(50.0, 'g'),
    'sugar': _NutrientRef(50.0, 'g'),
    'added sugars': _NutrientRef(50.0, 'g'),
    'added sugar': _NutrientRef(50.0, 'g'),

    // Protein
    'protein': _NutrientRef(54.0, 'g'),
    'proteins': _NutrientRef(54.0, 'g'),
    'crude protein': _NutrientRef(54.0, 'g'),

    // Minerals
    'sodium': _NutrientRef(2000.0, 'mg'),
    'salt': _NutrientRef(5000.0, 'mg'), // 5 g salt contains ~2,000 mg Sodium
    'potassium': _NutrientRef(3500.0, 'mg'),
    'potassium (k)': _NutrientRef(3500.0, 'mg'),
    'calcium': _NutrientRef(1000.0, 'mg'),
    'calcium (ca)': _NutrientRef(1000.0, 'mg'),
    'iron': _NutrientRef(19.0, 'mg'),
    'iron (fe)': _NutrientRef(19.0, 'mg'),
    'zinc': _NutrientRef(12.0, 'mg'),
    'zinc (zn)': _NutrientRef(12.0, 'mg'),
    'magnesium': _NutrientRef(385.0, 'mg'),
    'magnesium (mg)': _NutrientRef(385.0, 'mg'),
    'phosphorus': _NutrientRef(1000.0, 'mg'),
    'phosphorus (p)': _NutrientRef(1000.0, 'mg'),
    'iodine': _NutrientRef(140.0, 'mcg'),
    'iodine (i)': _NutrientRef(140.0, 'mcg'),
    'selenium': _NutrientRef(40.0, 'mcg'),
    'selenium (se)': _NutrientRef(40.0, 'mcg'),
    'copper': _NutrientRef(1.7, 'mg'),
    'copper (cu)': _NutrientRef(1.7, 'mg'),

    // Vitamins
    'vitamin a': _NutrientRef(1000.0, 'mcg'),
    'vitamin a (retinol)': _NutrientRef(1000.0, 'mcg'),
    'retinol': _NutrientRef(1000.0, 'mcg'),
    'vitamin c': _NutrientRef(80.0, 'mg'),
    'vitamin c (ascorbic acid)': _NutrientRef(80.0, 'mg'),
    'ascorbic acid': _NutrientRef(80.0, 'mg'),
    'vitamin d': _NutrientRef(15.0, 'mcg'),
    'vitamin d (d2/d3)': _NutrientRef(15.0, 'mcg'),
    'vitamin d2': _NutrientRef(15.0, 'mcg'),
    'vitamin d3': _NutrientRef(15.0, 'mcg'),
    'vitamin e': _NutrientRef(15.0, 'mg'),
    'vitamin e (tocopherol)': _NutrientRef(15.0, 'mg'),
    'tocopherol': _NutrientRef(15.0, 'mg'),
    'vitamin k': _NutrientRef(55.0, 'mcg'),
    'vitamin k (phylloquinone)': _NutrientRef(55.0, 'mcg'),
    'phylloquinone': _NutrientRef(55.0, 'mcg'),
    'vitamin b1': _NutrientRef(1.4, 'mg'),
    'vitamin b1 (thiamine)': _NutrientRef(1.4, 'mg'),
    'thiamine': _NutrientRef(1.4, 'mg'),
    'thiamin': _NutrientRef(1.4, 'mg'),
    'vitamin b2': _NutrientRef(1.6, 'mg'),
    'vitamin b2 (riboflavin)': _NutrientRef(1.6, 'mg'),
    'riboflavin': _NutrientRef(1.6, 'mg'),
    'vitamin b3': _NutrientRef(14.0, 'mg'),
    'vitamin b3 (niacin)': _NutrientRef(14.0, 'mg'),
    'niacin': _NutrientRef(14.0, 'mg'),
    'vitamin b6': _NutrientRef(1.9, 'mg'),
    'vitamin b6 (pyridoxine)': _NutrientRef(1.9, 'mg'),
    'pyridoxine': _NutrientRef(1.9, 'mg'),
    'vitamin b9': _NutrientRef(200.0, 'mcg'),
    'vitamin b9 (folic acid)': _NutrientRef(200.0, 'mcg'),
    'folic acid': _NutrientRef(200.0, 'mcg'),
    'folate': _NutrientRef(200.0, 'mcg'),
    'vitamin b12': _NutrientRef(2.2, 'mcg'),
    'vitamin b12 (cobalamin)': _NutrientRef(2.2, 'mcg'),
    'cobalamin': _NutrientRef(2.2, 'mcg'),
  };

  /// Calculates the % Daily Value / % RDA for Calories per serving against 2,000 kcal.
  static String calculateCaloriesRda(dynamic calPerServe) {
    final cal = (calPerServe is num)
        ? calPerServe.toDouble()
        : double.tryParse(calPerServe.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (cal <= 0) return '0%';
    final pct = (cal / referenceDailyCaloriesKcal) * 100.0;
    return '${pct.round()}%';
  }

  /// Calculates the % Daily Value / % RDA for a specific nutrient row.
  ///
  /// Takes:
  /// - [label]: Nutrient display name (e.g. 'Total Fat', '— Saturated Fat', 'Sodium')
  /// - [value]: Value string or number (e.g. '10', '222 mg', '1.2')
  /// - [unit]: Optional unit (e.g. 'g', 'mg', 'mcg', 'kcal'). If omitted, extracts from [value].
  /// - [servingSizeGrams]: Packaging serving size in grams (e.g. 70, 30).
  ///
  /// Returns a clean percentage string like `'10%'`, `'3%'`, `'0%'`, or `'-'` if unknown.
  static String calculateRdaPercentage({
    required String label,
    required String value,
    String? unit,
    required double servingSizeGrams,
  }) {
    final cleanLabel = label
        .replaceAll(RegExp(r'^[—•\-\*\s]+'), '')
        .trim()
        .toLowerCase();

    final ref = _rdaTable[cleanLabel];
    if (ref == null) {
      return '-';
    }

    // Extract numeric amount
    final numMatch = RegExp(r'[-+]?[0-9]*\.?[0-9]+').firstMatch(value);
    if (numMatch == null) {
      return '-';
    }
    final rawVal = double.tryParse(numMatch.group(0) ?? '') ?? 0.0;

    // Determine unit
    String effectiveUnit = (unit != null && unit.trim().isNotEmpty)
        ? unit.trim().toLowerCase()
        : '';
    if (effectiveUnit.isEmpty) {
      final unitMatch = RegExp(r'[a-zA-Zµ]+').firstMatch(value.substring(numMatch.end));
      effectiveUnit = unitMatch?.group(0)?.toLowerCase() ?? ref.baseUnit;
    }

    // Scale from per-100g CoA value to per-serving value
    final double serveScale = (servingSizeGrams > 0) ? (servingSizeGrams / 100.0) : 1.0;
    final double serveAmount = rawVal * serveScale;

    // Convert unit to reference base unit
    final double unitFactor = _getUnitConversionFactor(fromUnit: effectiveUnit, toUnit: ref.baseUnit);
    final double normalizedAmount = serveAmount * unitFactor;

    if (ref.dailyValue <= 0) {
      return '-';
    }

    final double pct = (normalizedAmount / ref.dailyValue) * 100.0;
    if (pct <= 0.0) {
      return '0%';
    } else if (pct < 0.5) {
      // Very small trace amounts (<0.5%) round to 0% in standard packaging rules
      return '0%';
    } else {
      return '${pct.round()}%';
    }
  }

  /// Converts an input unit to the target base unit.
  static double _getUnitConversionFactor({
    required String fromUnit,
    required String toUnit,
  }) {
    if (fromUnit == toUnit) return 1.0;

    // Normalize spellings
    String from = fromUnit.replaceAll('µ', 'mc').replaceAll('ug', 'mcg');
    String to = toUnit.replaceAll('µ', 'mc').replaceAll('ug', 'mcg');

    if (from == to) return 1.0;

    // Grams base
    if (to == 'g') {
      if (from == 'mg') return 0.001;
      if (from == 'mcg') return 0.000001;
      if (from == 'kg') return 1000.0;
    }

    // Milligrams base
    if (to == 'mg') {
      if (from == 'g') return 1000.0;
      if (from == 'mcg') return 0.001;
      if (from == 'kg') return 1000000.0;
    }

    // Micrograms base
    if (to == 'mcg') {
      if (from == 'mg') return 1000.0;
      if (from == 'g') return 1000000.0;
      if (from == 'iu') return 0.025; // 1 mcg Vit D = 40 IU
    }

    // Energy base (kcal)
    if (to == 'kcal') {
      if (from == 'cal') return 0.001;
      if (from == 'kj') return 1.0 / 4.184;
    }

    return 1.0;
  }
}

class _NutrientRef {
  final double dailyValue;
  final String baseUnit;

  const _NutrientRef(this.dailyValue, this.baseUnit);
}
