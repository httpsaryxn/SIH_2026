import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/small_business/presentation/screens/create_label_declaration_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/ingredients_allergens_screen.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('Screen 1 to Screen 2 to Screen 3 full navigation flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyLabelStudioApp());

    // Verify Screen 1 key elements
    expect(find.text('My Label Studio'), findsOneWidget);
    expect(find.text('Create a new label'), findsOneWidget);

    // Tap CTA on Screen 1 to navigate to Screen 2
    final createLabelBtn = find.text('Start creating your label');
    expect(createLabelBtn, findsOneWidget);
    await tester.tap(createLabelBtn);
    await tester.pumpAndSettle();

    // Verify Screen 2 elements
    expect(find.text('Create Label'), findsOneWidget);
    expect(find.text('Step 1 of 6'), findsOneWidget);
    expect(find.text('Declaration'), findsOneWidget);

    // Fill in required fields on Screen 2
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'Annapurna');
    await tester.enterText(textFields.at(1), 'Mango Pickle');
    await tester.pumpAndSettle();

    // Tap Continue on Screen 2 to navigate to Screen 3
    final continueBtnScreen2 = find.text('Continue');
    expect(continueBtnScreen2, findsOneWidget);
    await tester.tap(continueBtnScreen2);
    await tester.pumpAndSettle();

    // Verify Screen 3 elements
    expect(find.text('Label Studio'), findsOneWidget);
    expect(find.text('Step 2 of 6'), findsOneWidget);
    expect(find.text('33% complete'), findsOneWidget);
    expect(find.text('Ingredients'), findsWidgets);
    expect(find.text('No lab report'), findsOneWidget);
    expect(find.text('Search ingredients'), findsOneWidget);
    expect(find.text('No ingredients added'), findsOneWidget);
    expect(find.text('Allergen Declaration'), findsOneWidget);
    expect(find.text('Peanuts'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);

    // Tap Back on Screen 3 to verify return to Screen 2
    final backBtnScreen3 = find.text('Back');
    expect(backBtnScreen3, findsOneWidget);
    await tester.tap(backBtnScreen3);
    await tester.pumpAndSettle();

    // Verify back on Screen 2
    expect(find.text('Create Label'), findsOneWidget);
    expect(find.text('Declaration'), findsOneWidget);
  });

  testWidgets('Screen 3 direct test with interactive elements', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: IngredientsAllergensScreen()),
    );

    // Verify initial render
    expect(find.text('Label Studio'), findsOneWidget);
    expect(find.text('Step 2 of 6'), findsOneWidget);
    expect(find.text('33% complete'), findsOneWidget);
    expect(find.text('0'), findsOneWidget); // Count badge

    // Toggle segmented control
    await tester.tap(find.text('I have a lab report'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Upload your accredited laboratory'),
      findsOneWidget,
    );

    // Switch back to No lab report
    await tester.tap(find.text('No lab report'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining("We'll help you compile ingredients manually"),
      findsOneWidget,
    );
  });
}
