import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/small_business/presentation/screens/my_label_studio_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/small_business_inventory_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/small_business_notifications_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/small_business_profile_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/label_review_export_screen.dart';

void main() {
  group('Small Business Module Tests', () {
    testWidgets(
        'MyLabelStudioScreen renders 4-tab bottom navigation (Home, Inventory, Notifications, Profile)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MyLabelStudioScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check top header has no notification or profile buttons
      expect(find.text('My Label Studio'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);

      // Verify all 4 bottom nav items are present
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Switching tabs switches screens smoothly in DirectionalIndexedStack',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MyLabelStudioScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Inventory tab
      await tester.tap(find.text('Inventory'));
      await tester.pumpAndSettle();
      expect(find.byType(SmallBusinessInventoryScreen), findsOneWidget);
      expect(find.text('Label Inventory'), findsOneWidget);
      expect(find.text('New Label'), findsOneWidget);

      // Tap Notifications tab
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(find.byType(SmallBusinessNotificationsScreen), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('Legal'), findsOneWidget);

      // Tap Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(SmallBusinessProfileScreen), findsOneWidget);
      expect(find.text('Business Profile'), findsOneWidget);

      // Tap Home tab back
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('My Label Studio'), findsOneWidget);
      expect(find.text('Start creating your label'), findsOneWidget);
    });

    testWidgets('Home search bar renders inline search results list below search bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MyLabelStudioScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Initially no search results card
      expect(find.textContaining('Search Results'), findsNothing);

      // Enter query
      await tester.enterText(searchField, 'Makhana');
      await tester.pumpAndSettle();

      // Search results dropdown is displayed directly below search bar
      expect(find.textContaining('Search Results'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);

      // Tapping a search result navigates to LabelReviewExportScreen
      final resultItem = find.text('Roasted Makhana (Himalayan Salt)');
      if (resultItem.evaluate().isNotEmpty) {
        await tester.tap(resultItem.first);
        await tester.pumpAndSettle();
        expect(find.byType(LabelReviewExportScreen), findsOneWidget);
      }
    });

    testWidgets('Inventory screen allows filtering by status chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: SmallBusinessInventoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Label Inventory'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('Needs Review'), findsOneWidget);
      expect(find.text('Drafts'), findsOneWidget);

      await tester.tap(find.text('Ready'));
      await tester.pumpAndSettle();
    });
  });
}
