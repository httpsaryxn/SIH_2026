import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/summary_gen_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Consumer Summary Tests', () {
    test('Flags high sodium, synthetic colors, and palm oil from OCR text', () async {
      const sampleNoodlesOcr = '''
      MAGGI 2-MINUTE NOODLES
      Ingredients: Wheat flour, palm oil, salt, mineral (calcium carbonate).
      Tastemaker: Hydrolysed groundnut protein, mixed spices, noodle powder (wheat flour, palm oil, salt),
      sugar, edible starch, flavour enhancer (621), acidity regulators (330, 500ii),
      colour (INS 102 - Tartrazine), mineral (iron).
      NUTRITION INFORMATION (Per 100g):
      Energy: 427 kcal
      Protein: 8.0 g
      Carbohydrate: 63.5 g
      Total Sugars: 2.2 g
      Total Fat: 15.7 g
      Sodium: 980 mg
      FSSAI Lic. No. 10012011000168
      ''';

      final result = await SummaryGenClient.summarizeConsumer(
        productName: 'Instant Masala Noodles',
        manufacturer: 'Nestle India Ltd',
        declarations: {
          'net_quantity': '70 g',
          'mrp': 14.0,
          'fssai': '10012011000168',
        },
        ocrText: sampleNoodlesOcr,
      );

      expect(result.isFood, isTrue);
      expect(result.summaryText, contains('⚠️ Health & Ingredient Concerns'));
      expect(result.summaryText, contains('Excessive Sodium'));
      expect(result.summaryText, contains('980mg'));
      expect(result.summaryText, contains('Synthetic Food Colors'));
      expect(result.summaryText, contains('Tartrazine'));
      expect(result.summaryText, contains('Refined Palm Fat'));
      expect(result.summaryText, contains('Flavour Enhancer (MSG'));
      expect(result.healthScore, isNotNull);
      expect(result.healthScore! <= 55, isTrue);
    });

    test('Provides positive reassurance for clean, wholesome product', () async {
      const sampleCleanOatsOcr = '''
      QUAKER 100% WHOLE GRAIN ROLLED OATS
      Ingredients: 100% Natural Wholegrain Rolled Oats.
      No added sugar. No preservatives. No artificial flavours or colours.
      NUTRITION INFORMATION (Per 100g):
      Energy: 395 kcal
      Protein: 12.5 g
      Dietary Fibre: 10.0 g
      Total Sugars: 0.8 g
      Sodium: 4 mg
      FSSAI Lic. No. 10014064000435
      ''';

      final result = await SummaryGenClient.summarizeConsumer(
        productName: 'Whole Grain Rolled Oats',
        manufacturer: 'PepsiCo India Holdings',
        declarations: {
          'net_quantity': '500 g',
          'mrp': 120.0,
          'fssai': '10014064000435',
        },
        ocrText: sampleCleanOatsOcr,
      );

      expect(result.isFood, isTrue);
      expect(result.summaryText, contains('✅ Clean Formulation & Safe Nutrition'));
      expect(result.summaryText, contains('No Harmful Synthetic Dyes'));
      expect(result.summaryText, contains('No Concerning Preservatives'));
      expect(result.summaryText, contains('Safe Thresholds'));
      expect(result.healthScore, isNotNull);
      expect(result.healthScore! >= 80, isTrue);
    });

    test('Identifies medicinal products and displays mandatory disclaimer', () async {
      const samplePharmaOcr = '''
      BENADRYL COUGH FORMULA SYRUP
      Each 5ml contains: Diphenhydramine Hydrochloride IP 14.05mg, Ammonium Chloride IP 138mg.
      Dosage: As directed by physician. Schedule H Prescription Drug.
      Storage: Store below 25C. Keep out of reach of children.
      ''';

      final result = await SummaryGenClient.summarizeConsumer(
        productName: 'Cough Formula Syrup',
        manufacturer: 'Johnson & Johnson Pvt Ltd',
        declarations: {
          'net_quantity': '100 ml',
          'mrp': 115.0,
        },
        ocrText: samplePharmaOcr,
      );

      expect(result.isMedicinal, isTrue);
      expect(result.summaryText, contains('Declared Commodity'));
      expect(result.summaryText, contains('Informational summary of declared label content only. Not medical advice.'));
      expect(result.healthScore, isNull);
    });
  });
}
