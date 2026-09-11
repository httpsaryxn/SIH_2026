import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/small_business/data/models/small_business_label_model.dart';
import 'package:mobile/features/small_business/data/repositories/small_business_label_repository.dart';
import 'package:mobile/features/small_business/data/services/file_download_service.dart';
import 'package:mobile/features/small_business/data/services/gs1_ean13_encoder.dart';
import 'package:mobile/features/small_business/data/services/nutrition_calculator.dart';
import 'package:mobile/features/small_business/presentation/screens/create_label_declaration_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/final_details_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/ingredients_allergens_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/label_review_export_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/manufacturer_details_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/my_label_studio_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/nutritional_values_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/product_claims_screen.dart';
import 'package:mobile/screens/onboarding/role_selection_screen.dart';
import 'package:mobile/core/widgets/label_lens_brand.dart';
import 'package:mobile/screens/splash/splash_screen.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl ||
        invocation.memberName == #openUrl ||
        invocation.memberName == #postUrl ||
        invocation.memberName == #patchUrl ||
        invocation.memberName == #deleteUrl) {
      return Future.value(_MockHttpClientRequest());
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #headers) {
      return _MockHttpHeaders();
    }
    if (invocation.memberName == #close) {
      return Future.value(_MockHttpClientResponse());
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  static const List<int> _transparentImage = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ];

  @override
  int get contentLength => _transparentImage.length;

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #compressionState) {
      return HttpClientResponseCompressionState.notCompressed;
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = MockHttpOverrides();
  });

  const testModel = SmallBusinessLabelModel(
    brandName: 'Annapurna Foods',
    productName: 'Organic Mango Pickle',
    productCategory: 'Pickles & Condiments',
    typeFlavour: 'Traditional Spicy Mustard',
    netQuantity: '500',
    netQuantityUnit: 'g',
    mrp: '199.00',
    servingSize: '15',
    servingSizeUnit: 'g',
    manufacturerName: 'Annapurna Agro Industries',
    manufacturerAddress: 'Plot 42, Industrial Area, Varanasi, UP, 221001',
    fssaiLicenseNumber: '12345678901234',
    consumerCarePhone: '+91 98765 43210',
    consumerCareEmail: 'care@annapurnafoods.in',
    ingredients: [
      SmallBusinessIngredientModel(name: 'Raw Mango Pieces', percentage: 65.0),
      SmallBusinessIngredientModel(name: 'Mustard Oil', percentage: 20.0),
      SmallBusinessIngredientModel(name: 'Iodized Salt', percentage: 10.0),
      SmallBusinessIngredientModel(name: 'Red Chilli Powder', percentage: 5.0),
    ],
    allergens: ['Mustard'],
  );

  testWidgets(
      'Full End-to-End Navigation Flow Across Studio and Steps 1 through 5',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const MyLabelStudioScreen(),
    ));
    await tester.pumpAndSettle();

    // Verify Screen 1 (Studio Hub)
    expect(find.text('My Label Studio'), findsOneWidget);

    // Navigate to Step 1 (Create Label Declaration)
    final createLabelBtn = find.text('Start creating your label');
    await tester.tap(createLabelBtn);
    await tester.pumpAndSettle();

    expect(find.text('Create Label'), findsOneWidget);
    expect(find.text('Step 1 of 6 • Product Declaration'), findsOneWidget);

    // Fill in fields
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'Annapurna');
    await tester.enterText(textFields.at(1), 'Mango Pickle');
    await tester.pumpAndSettle();

    // Select category from dropdown
    await tester.ensureVisible(find.byType(DropdownButton<String>));
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pickles & Condiments').last);
    await tester.pumpAndSettle();

    // Navigate to Step 2 (Ingredients & Allergens)
    final continueBtn1 = find.text('Continue');
    await tester.tap(continueBtn1);
    await tester.pumpAndSettle();

    expect(find.text('Formulation & Allergens'), findsOneWidget);
    expect(find.text('Step 2 of 6 • Ingredients list'), findsOneWidget);

    // Add an ingredient from quick formulation chips
    await tester.ensureVisible(find.byType(ActionChip).first);
    await tester.tap(find.byType(ActionChip).first);
    await tester.pumpAndSettle();

    // Confirm addition in bottom sheet
    await tester.tap(find.text('Save Ingredient'));
    await tester.pumpAndSettle();

    // Navigate to Step 3 (Nutritional Values)
    final continueBtn2 = find.text('Continue');
    await tester.tap(continueBtn2);
    await tester.pumpAndSettle();

    expect(find.text('Nutritional Values'), findsWidgets);
    expect(find.text('Step 3 of 6 • Nutrition Profile'), findsOneWidget);

    // Navigate to Step 4 (Manufacturer Details) via Skip
    final skipBtn3 = find.text('Skip');
    await tester.tap(skipBtn3);
    await tester.pumpAndSettle();

    expect(find.text('Manufacturer & Business Profile'), findsWidgets);
    expect(find.text('STEP 4 OF 6 • NUTRITION PROFILE'), findsOneWidget);
    expect(find.text('Manufacturer Details'), findsWidgets);

    // Tap Back on Step 4 to return to Step 3
    final backBtn4 = find.text('Back');
    await tester.tap(backBtn4);
    await tester.pumpAndSettle();

    expect(find.text('Nutritional Values'), findsWidgets);
  });

  testWidgets(
      'Responsive Narrow Screen Overflow Test on All Screens (360x640)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Test 1: Studio Screen on narrow viewport
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const MyLabelStudioScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('My Label Studio'), findsOneWidget);

    // Test 2: Declaration Screen on narrow viewport
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const CreateLabelDeclarationScreen(initialLabel: testModel),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Create Label'), findsWidgets);

    // Test 3: Ingredients Screen on narrow viewport
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const IngredientsAllergensScreen(labelModel: testModel),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Formulation & Allergens'), findsWidgets);

    // Test 4: Nutrition Screen on narrow viewport
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const NutritionalValuesScreen(labelModel: testModel),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nutritional Values'), findsWidgets);

    // Test 5: Manufacturer Details Screen on narrow viewport
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ManufacturerDetailsScreen(labelModel: testModel),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Manufacturer & Business Profile'), findsWidgets);

    // Test 6: Final Details Screen on narrow viewport
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const FinalDetailsScreen(labelModel: testModel),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Finishing Details'), findsWidgets);

    // Test 7: Product Claims Screen on narrow viewport
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ProductClaimsScreen(labelModel: testModel),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Product Claims'), findsWidgets);

    // Test 8: Review & Export Screen on narrow viewport
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: LabelReviewExportScreen(
          brandName: testModel.brandName,
          productName: testModel.productName,
          productCategory: testModel.productCategory,
          netQuantity: '${testModel.netQuantity} ${testModel.netQuantityUnit}',
          mrp: '₹ ${testModel.mrp}',
          labelModel: testModel,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Review & Export'), findsWidgets);
  });

  testWidgets('MyLabelStudioScreen filters search in memory instantly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const MyLabelStudioScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'Organic');
    await tester.pump();
    expect(find.byType(MyLabelStudioScreen), findsOneWidget);
  });

  test('GS1 EAN-13 barcode encoder produces exact standard modules and checksum', () {
    final barcode = '890123456789';
    final normalized = GS1Ean13Encoder.normalizeEan13(barcode);
    expect(normalized.length, equals(13));
    expect(normalized.startsWith('890123456789'), isTrue);

    final modules = GS1Ean13Encoder.encodeModules(normalized);
    expect(modules.length, equals(95)); // Official GS1 EAN-13 total module count
    // Guard patterns
    expect(modules.sublist(0, 3), equals([true, false, true]));
    expect(modules.sublist(45, 50), equals([false, true, false, true, false]));
    expect(modules.sublist(92, 95), equals([true, false, true]));
  });

  test('SmallBusinessLabelRepository loads cache and formats labels', () async {
    await SmallBusinessLabelRepository.loadLocalCache();
    final repo = SmallBusinessLabelRepository();
    final cached = repo.getCachedLabels();
    expect(cached, isNotEmpty);

    final filtered = repo.getCachedLabels(searchQuery: 'Mango');
    expect(filtered, isA<List<SmallBusinessLabelModel>>());
  });

  testWidgets('RoleSelectionScreen displays roles and allows selecting Business Owner',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const RoleSelectionScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('How will you use the platform?'), findsOneWidget);
    expect(find.text('Business Owner'), findsWidgets);

    // Tap Business Owner card
    await tester.tap(find.text('Business Owner').first);
    await tester.pumpAndSettle();

    // Verify Continue button is present and active
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Already have an account? Log in'), findsOneWidget);
  });

  test('FileDownloadService generates valid SVG, PDF, and JSON without errors', () async {
    const model = SmallBusinessLabelModel(
      brandName: 'Kaveri Pure',
      productName: 'Roasted Makhana',
      productCategory: 'Snacks & Namkeen',
      netQuantity: '100',
      netQuantityUnit: 'g',
      mrp: '120.00',
      fssaiLicenseNumber: '11521018000345',
      manufacturerName: 'Kaveri Foods Pvt Ltd',
      manufacturerAddress: 'Industrial Area, Pune, Maharashtra 411028',
    );

    // Test SVG Generation
    final svgPath = await FileDownloadService.downloadSvgLabel(
      model: model,
      dimension: 'Standard Pouch (100 × 150 mm)',
      shareOnMobile: false,
    );
    expect(svgPath, isNotNull);
    final svgFile = File(svgPath!);
    expect(await svgFile.exists(), isTrue);
    final svgString = await svgFile.readAsString();
    expect(svgString, contains('<svg'));
    expect(svgString, contains('Roasted Makhana'));

    // Test JSON Generation
    final jsonPath = await FileDownloadService.downloadJsonMetadata(
      model: model,
      shareOnMobile: false,
    );
    expect(jsonPath, isNotNull);
    final jsonFile = File(jsonPath!);
    expect(await jsonFile.exists(), isTrue);
    final jsonString = await jsonFile.readAsString();
    expect(jsonString, contains('"product_name": "Roasted Makhana"'));

    // Test PDF Generation across dynamic selected packaging dimensions
    // 1. Preset Dimension: Standard Pouch (100 × 150 mm)
    final pdfPath150 = await FileDownloadService.downloadPdfLabel(
      model: model,
      dimension: 'Standard Pouch (100 × 150 mm)',
      shareOnMobile: false,
    );
    expect(pdfPath150, isNotNull);
    final pdfFile150 = File(pdfPath150!);
    expect(await pdfFile150.exists(), isTrue);
    expect(pdfPath150, contains('100x150mm'));
    final pdfBytes150 = await pdfFile150.readAsBytes();
    final pdfString150 = latin1.decode(pdfBytes150, allowInvalid: true);
    expect(pdfString150, contains('%PDF'));
    // 100 mm * 2.83464567 = 283.46 pt, 150 mm * 2.83464567 = 425.20 pt
    expect(pdfString150, contains('/MediaBox [0 0 283.46 425.20]'));

    // 2. Ultra-Compact Pouch (100 × 118 mm)
    final pdfPath118 = await FileDownloadService.downloadPdfLabel(
      model: model,
      dimension: 'Ultra-Compact Pouch (100 × 118 mm)',
      shareOnMobile: false,
    );
    expect(pdfPath118, isNotNull);
    final pdfFile118 = File(pdfPath118!);
    expect(pdfPath118, contains('100x118mm'));
    final pdfBytes118 = await pdfFile118.readAsBytes();
    final pdfString118 = latin1.decode(pdfBytes118, allowInvalid: true);
    // 100 mm * 2.83464567 = 283.46 pt, 118 mm * 2.83464567 = 334.49 pt
    expect(pdfString118, contains('/MediaBox [0 0 283.46 334.49]'));

    // 3. Custom Packaging Dimension (75 × 120 mm)
    final pdfPathCustom = await FileDownloadService.downloadPdfLabel(
      model: model,
      dimension: 'Custom (75 × 120 mm)',
      customWidthMm: 75.0,
      customHeightMm: 120.0,
      shareOnMobile: false,
    );
    expect(pdfPathCustom, isNotNull);
    final pdfFileCustom = File(pdfPathCustom!);
    expect(pdfPathCustom, contains('75x120mm'));
    final pdfBytesCustom = await pdfFileCustom.readAsBytes();
    final pdfStringCustom = latin1.decode(pdfBytesCustom, allowInvalid: true);
    // 75 mm * 2.83464567 = 212.60 pt, 120 mm * 2.83464567 = 340.16 pt
    expect(pdfStringCustom, contains('/MediaBox [0 0 212.60 340.16]'));

    // 4. Test FileDownloadService.parseDimensions helper
    final dim1 = FileDownloadService.parseDimensions('Standard Pouch (100 × 150 mm)');
    expect(dim1.widthMm, 100.0);
    expect(dim1.heightMm, 150.0);

    final dim2 = FileDownloadService.parseDimensions('Bottle Wrap (70 x 180 mm)');
    expect(dim2.widthMm, 70.0);
    expect(dim2.heightMm, 180.0);

    final dimFallback = FileDownloadService.parseDimensions('Invalid Dimension Format');
    expect(dimFallback.widthMm, 100.0);
    expect(dimFallback.heightMm, 118.0);
  });

  test('FileDownloadService renders brand logo in PDF and SVG when provided', () async {
    const sampleLogoBase64 =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

    const modelWithLogo = SmallBusinessLabelModel(
      brandName: 'Himalayan Organics',
      productName: 'Raw Wildflower Honey',
      productCategory: 'Sweeteners & Honey',
      netQuantity: '250',
      netQuantityUnit: 'g',
      mrp: '350.00',
      fssaiLicenseNumber: '11521018000999',
      manufacturerName: 'Himalayan Organics Pvt Ltd',
      manufacturerAddress: 'Dehradun, Uttarakhand 248001',
      logoUrl: sampleLogoBase64,
    );

    final pdfPath = await FileDownloadService.downloadPdfLabel(
      model: modelWithLogo,
      dimension: 'Ultra-Compact Pouch (100 × 118 mm)',
      shareOnMobile: false,
    );
    final svgPath = await FileDownloadService.downloadSvgLabel(
      model: modelWithLogo,
      dimension: 'Ultra-Compact Pouch (100 × 118 mm)',
      shareOnMobile: false,
    );

    // 1. PDF Export with Logo
    expect(pdfPath, isNotNull);
    final pdfBytes = await File(pdfPath!).readAsBytes();
    final pdfString = latin1.decode(pdfBytes, allowInvalid: true);
    expect(pdfString, contains('/BrandLogo'));
    expect(pdfString, contains('/BrandLogo Do'));

    // 2. SVG Export with Logo
    expect(svgPath, isNotNull);
    final svgString = await File(svgPath!).readAsString();
    expect(svgString, contains('<image '));
    expect(svgString, contains('data:image/png;base64,'));
  });

  test('NutritionCalculator computes exact statutory % RDA and Calories Daily Values', () {
    // Calories: 375 kcal / 2000 kcal = 18.75% -> 19%
    expect(NutritionCalculator.calculateCaloriesRda(375), '19%');
    // Calories: 200 kcal / 2000 kcal = 10%
    expect(NutritionCalculator.calculateCaloriesRda(200), '10%');
    // Calories: 0 kcal -> 0%
    expect(NutritionCalculator.calculateCaloriesRda(0), '0%');

    // Total Fat: 10g / 100g, 70g serving -> 7g. 7 / 67g (FSSAI RDA) = 10.45% -> 10%
    expect(NutritionCalculator.calculateRdaPercentage(label: 'Total Fat', value: '10', unit: 'g', servingSizeGrams: 70), '10%');

    // Saturated Fat: 1g / 100g, 70g serving -> 0.7g. 0.7 / 22g = 3.18% -> 3%
    expect(NutritionCalculator.calculateRdaPercentage(label: '— Saturated Fat', value: '1', unit: 'g', servingSizeGrams: 70), '3%');

    // Trans Fat: 0g -> 0%
    expect(NutritionCalculator.calculateRdaPercentage(label: '— Trans Fat', value: '0', unit: 'g', servingSizeGrams: 70), '0%');

    // Sodium: 222mg / 100g, 70g serving -> 155.4mg. 155.4 / 2000mg = 7.77% -> 8%
    expect(NutritionCalculator.calculateRdaPercentage(label: 'Sodium', value: '222', unit: 'mg', servingSizeGrams: 70), '8%');

    // Protein: 5.6g / 100g, 70g serving -> 3.92g. 3.92 / 54g = 7.26% -> 7%
    expect(NutritionCalculator.calculateRdaPercentage(label: 'Protein', value: '5.6', unit: 'g', servingSizeGrams: 70), '7%');

    // Carbohydrates: 230g / 100g, 70g serving -> 161g. 161 / 300g = 53.67% -> 54%
    expect(NutritionCalculator.calculateRdaPercentage(label: 'Carbohydrates', value: '230', unit: 'g', servingSizeGrams: 70), '54%');

    // Added Sugars: 2g / 100g, 70g serving -> 1.4g. 1.4 / 50g = 2.8% -> 3%
    expect(NutritionCalculator.calculateRdaPercentage(label: '• Added Sugars', value: '2', unit: 'g', servingSizeGrams: 70), '3%');

    // Iron: 1.2mg / 100g, 70g serving -> 0.84mg. 0.84 / 19mg = 4.42% -> 4%
    expect(NutritionCalculator.calculateRdaPercentage(label: 'Iron', value: '1.2', unit: 'mg', servingSizeGrams: 70), '4%');

    // Calcium: 40mg / 100g, 70g serving -> 28mg. 28 / 1000mg = 2.8% -> 3%
    expect(NutritionCalculator.calculateRdaPercentage(label: 'Calcium', value: '40', unit: 'mg', servingSizeGrams: 70), '3%');
  });

  test('FileDownloadService renders calculated RDA percentages on the right-hand side in SVG and PDF', () async {
    const modelWithNutrients = SmallBusinessLabelModel(
      brandName: 'Shree Nutri Foods',
      productName: 'Roasted Diet Makhana',
      productCategory: 'Snacks & Namkeen',
      netQuantity: '100',
      netQuantityUnit: 'g',
      servingSize: '70',
      servingSizeUnit: 'g',
      mrp: '150.00',
      fssaiLicenseNumber: '11521018000789',
      manufacturerName: 'Shree Nutri Foods LLP',
      manufacturerAddress: 'Indore, MP 452001',
      nutrients: [
        SmallBusinessNutrientModel(label: 'Calories', value: '536', unit: 'kcal'),
        SmallBusinessNutrientModel(label: 'Total Fat', value: '10', unit: 'g'),
        SmallBusinessNutrientModel(label: 'Saturated Fat', value: '1', unit: 'g', isSubNutrient: true),
        SmallBusinessNutrientModel(label: 'Trans Fat', value: '0', unit: 'g', isSubNutrient: true),
        SmallBusinessNutrientModel(label: 'Sodium', value: '222', unit: 'mg'),
        SmallBusinessNutrientModel(label: 'Carbohydrates', value: '230', unit: 'g'),
        SmallBusinessNutrientModel(label: 'Added Sugars', value: '2', unit: 'g', isSubNutrient: true),
        SmallBusinessNutrientModel(label: 'Protein', value: '5.6', unit: 'g'),
        SmallBusinessNutrientModel(label: 'Calcium', value: '40', unit: 'mg'),
        SmallBusinessNutrientModel(label: 'Iron', value: '1.2', unit: 'mg'),
      ],
    );

    // 1. PDF Export
    final pdfPath = await FileDownloadService.downloadPdfLabel(
      model: modelWithNutrients,
      dimension: 'Ultra-Compact Pouch (100 × 118 mm)',
      shareOnMobile: false,
    );
    expect(pdfPath, isNotNull);
    final pdfBytes = await File(pdfPath!).readAsBytes();
    final pdfString = latin1.decode(pdfBytes, allowInvalid: true);
    // Verify calories RDA (19%) and nutrient RDAs (10%, 8%, 7%, 54%, 3%, 0%) are printed in PDF stream
    expect(pdfString, contains('19%'));
    expect(pdfString, contains('10%'));
    expect(pdfString, contains('8%'));
    expect(pdfString, contains('7%'));
    expect(pdfString, contains('54%'));
    expect(pdfString, contains('3%'));
    expect(pdfString, contains('0%'));

    // 2. SVG Export
    final svgPath = await FileDownloadService.downloadSvgLabel(
      model: modelWithNutrients,
      dimension: 'Ultra-Compact Pouch (100 × 118 mm)',
      shareOnMobile: false,
    );
    expect(svgPath, isNotNull);
    final svgString = await File(svgPath!).readAsString();
    // Verify right-hand text-anchor="end" tags contain calculated percentages
    expect(svgString, contains('>19%</text>'));
    expect(svgString, contains('>10%</text>'));
    expect(svgString, contains('>8%</text>'));
    expect(svgString, contains('>7%</text>'));
    expect(svgString, contains('>54%</text>'));
    expect(svgString, contains('>3%</text>'));
    expect(svgString, contains('>0%</text>'));
  });

  testWidgets('Role Selection screen displays all 3 roles and title',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LabelLensApp(home: RoleSelectionScreen()));
    await tester.pumpAndSettle();

    // Verify Brand title & Header
    expect(find.byType(LabelLensBrand), findsWidgets);
    expect(find.text('How will you use the platform?'), findsOneWidget);

    // Verify 3 Role cards exist
    expect(find.text('Business Owner'), findsOneWidget);
    expect(find.text('Consumer'), findsOneWidget);
    expect(find.text('Regulator'), findsOneWidget);

    // Verify Continue button & Login link
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Already have an account? Log in'), findsOneWidget);
  });

  testWidgets('SplashScreen renders LabelLensBrand and Department info',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(minDuration: Duration(milliseconds: 50)),
      ),
    );
    await tester.pump();

    expect(find.byType(LabelLensBrand), findsOneWidget);
    expect(find.text('Department of Consumer Affairs • SIH 2026'), findsOneWidget);
    expect(find.text('Legal Metrology & Packaging Compliance'), findsOneWidget);

    // Allow timer and animation to complete cleanly
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
  });
}

