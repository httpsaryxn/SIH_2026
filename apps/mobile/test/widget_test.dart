import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('Role Selection screen displays all 3 roles and title', (WidgetTester tester) async {
    await tester.pumpWidget(const FreshLabelApp());

    // Verify Brand title & Header
    expect(find.text('FreshLabel Pro'), findsWidgets);
    expect(find.text('How will you use the platform?'), findsOneWidget);

    // Verify 3 Role cards exist
    expect(find.text('Business Owner'), findsOneWidget);
    expect(find.text('Consumer'), findsOneWidget);
    expect(find.text('Regulator'), findsOneWidget);

    // Verify Continue button & Login link
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Already have an account? Log in'), findsOneWidget);
  });
}
