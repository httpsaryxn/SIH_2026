import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/consumer_complaint_model.dart';
import 'package:mobile/core/models/consumer_saved_product.dart';
import 'package:mobile/core/models/consumer_scan_model.dart';
import 'package:mobile/core/models/product_model.dart';
import 'package:mobile/screens/consumer/widgets/my_complaints_section.dart';
import 'package:mobile/screens/consumer/widgets/quick_feature_strip.dart';
import 'package:mobile/screens/consumer/widgets/recent_scans_section.dart';
import 'package:mobile/screens/consumer/widgets/report_issue_hero_card.dart';
import 'package:mobile/screens/consumer/widgets/saved_products_section.dart';
import 'package:mobile/screens/consumer/widgets/scan_hero_card.dart';

void main() {
  group('Consumer Models Tests', () {
    test('ProductModel parses and serializes correctly', () {
      final product = ProductModel(
        id: 'prod-123',
        barcode: '8901234567890',
        productName: 'Choco Crisp Cereal',
        brand: 'MegaFoods',
        category: 'Breakfast',
        netQuantity: '300 g',
        mrp: 199.0,
        ingredients: ['Wheat', 'Cocoa', 'Sugar'],
        nutritionFacts: {'calories': '380 kcal'},
        complianceStatus: 'warning',
      );

      final json = product.toJson();
      expect(json['product_name'], 'Choco Crisp Cereal');
      expect(json['mrp'], 199.0);

      final parsed = ProductModel.fromJson(json);
      expect(parsed.id, 'prod-123');
      expect(parsed.ingredients.length, 3);
      expect(parsed.complianceStatus, 'warning');
    });

    test('ConsumerScanModel timeAgo calculation', () {
      final scanNow = ConsumerScanModel(
        id: 's-1',
        consumerId: 'u-1',
        productName: 'Bread',
        scannedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(scanNow.timeAgo, '5m ago');

      final scanHours = ConsumerScanModel(
        id: 's-2',
        consumerId: 'u-1',
        productName: 'Milk',
        scannedAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(scanHours.timeAgo, '3h ago');
    });

    test('ConsumerComplaintModel displayStatus and formattedDate', () {
      final complaint = ConsumerComplaintModel(
        id: 'c-1',
        complaintCode: '#CPL-8924',
        consumerId: 'u-1',
        productName: 'Choco Crisp',
        issueCategory: 'Missing Allergen Warning',
        description: 'Font is too small',
        status: 'under_review',
        createdAt: DateTime(2026, 10, 12),
      );

      expect(complaint.displayStatus, 'Under Review');
      expect(complaint.formattedDate, 'Oct 12');
    });
  });

  group('Consumer Widgets Rendering Tests', () {
    testWidgets('ScanHeroCard renders title, description, and action buttons', (tester) async {
      bool scanClicked = false;
      bool uploadClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanHeroCard(
              onScanPressed: () => scanClicked = true,
              onUploadPressed: () => uploadClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Scan a Product Label'), findsOneWidget);
      expect(find.text('Scan Label'), findsOneWidget);
      expect(find.text('Upload Image'), findsOneWidget);

      await tester.tap(find.text('Scan Label'));
      expect(scanClicked, true);

      await tester.tap(find.text('Upload Image'));
      expect(uploadClicked, true);
    });

    testWidgets('QuickFeatureStrip renders Ingredients, Nutrition, and Label Check', (tester) async {
      String? selectedFeature;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickFeatureStrip(
              onFeatureTap: (feat) => selectedFeature = feat,
            ),
          ),
        ),
      );

      expect(find.text('Ingredients'), findsOneWidget);
      expect(find.text('Nutrition'), findsOneWidget);
      expect(find.text('Label Check'), findsOneWidget);

      await tester.tap(find.text('Ingredients'));
      expect(selectedFeature, 'ingredients');
    });

    testWidgets('RecentScansSection renders scan items and compliance status tags', (tester) async {
      final dummyScans = [
        ConsumerScanModel(
          id: 's-1',
          consumerId: 'u-1',
          productName: 'Artisan Sourdough',
          brand: 'Local Bakery',
          netQuantity: '450g',
          complianceStatus: 'compliant',
          scannedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        ConsumerScanModel(
          id: 's-2',
          consumerId: 'u-1',
          productName: 'Choco Crisp',
          brand: 'MegaFoods',
          netQuantity: '300g',
          complianceStatus: 'warning',
          scannedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentScansSection(
              scans: dummyScans,
              onScanTap: (_) {},
              onViewAllTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Recently Scanned'), findsOneWidget);
      expect(find.text('Artisan Sourdough'), findsOneWidget);
      expect(find.text('No issues'), findsOneWidget);
      expect(find.text('Choco Crisp'), findsOneWidget);
      expect(find.text('Potential issue'), findsOneWidget);
    });

    testWidgets('SavedProductsSection renders bookmarks list and handles unsave', (tester) async {
      bool unsaved = false;
      final dummySaved = [
        ConsumerSavedProduct(
          id: 'b-1',
          consumerId: 'u-1',
          productId: 'p-1',
          productName: 'Organic Almond Milk',
          brand: "Nature's Best",
          quantity: '1L',
          savedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavedProductsSection(
              savedProducts: dummySaved,
              onProductTap: (_) {},
              onUnsaveTap: (_) => unsaved = true,
            ),
          ),
        ),
      );

      expect(find.text('Saved Products'), findsOneWidget);
      expect(find.text('Organic Almond Milk'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove bookmark'));
      expect(unsaved, true);
    });

    testWidgets('ReportIssueHeroCard renders CTA and trigger callback', (tester) async {
      bool reportPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportIssueHeroCard(
              onReportTap: () => reportPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('See something wrong?'), findsOneWidget);
      expect(find.text('Report an Issue'), findsOneWidget);

      await tester.tap(find.text('Report an Issue'));
      expect(reportPressed, true);
    });

    testWidgets('MyComplaintsSection renders complaint items and status tags', (tester) async {
      final dummyComplaints = [
        ConsumerComplaintModel(
          id: 'c-1',
          complaintCode: '#CPL-8924',
          consumerId: 'u-1',
          productName: 'Choco Crisp 300g',
          issueCategory: 'Missing Allergen Warning',
          description: 'Font illegible',
          status: 'under_review',
          createdAt: DateTime(2026, 10, 12),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyComplaintsSection(
              complaints: dummyComplaints,
              onComplaintTap: (_) {},
              onViewAllTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('My Complaints'), findsOneWidget);
      expect(find.text('Missing Allergen Warning'), findsOneWidget);
      expect(find.text('Under Review'), findsOneWidget);
      expect(find.text('Choco Crisp 300g'), findsOneWidget);
      expect(find.text('View All Complaints'), findsOneWidget);
    });
  });
}
