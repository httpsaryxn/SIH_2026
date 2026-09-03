import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/small_business/data/models/small_business_label_model.dart';
import 'package:mobile/features/small_business/presentation/screens/create_label_declaration_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/final_details_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/ingredients_allergens_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/label_review_export_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/manufacturer_details_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/my_label_studio_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/nutritional_values_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/product_claims_screen.dart';
import 'package:mobile/main.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl || invocation.memberName == #openUrl) {
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

    await tester.pumpWidget(const MyLabelStudioApp());
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
}
