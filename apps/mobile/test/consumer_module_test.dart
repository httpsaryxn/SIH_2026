import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/consumer_complaint_model.dart';
import 'package:mobile/core/models/consumer_scan_model.dart';
import 'package:mobile/core/models/product_model.dart';
import 'package:mobile/screens/consumer/widgets/complaint_detail_modal.dart';
import 'package:mobile/screens/consumer/widgets/my_complaints_section.dart';
import 'package:mobile/screens/consumer/widgets/quick_feature_strip.dart';
import 'package:mobile/screens/consumer/widgets/recent_scans_section.dart';
import 'package:mobile/screens/consumer/widgets/scan_hero_card.dart';

void main() {
  group('Consumer Models Tests', () {
    test('ProductModel parses Legal Metrology and nutrition data', () {
      final product = ProductModel(
        id: 'prod-123',
        barcode: '8901234567890',
        productName: 'Choco Crisp Cereal',
        brand: 'MegaFoods',
        category: 'Breakfast',
        netQuantity: '300 g',
        mrp: 199.0,
        ingredients: ['Wheat', 'Cocoa', 'Sugar'],
        nutritionFacts: {'calories': '380 kcal', 'protein': '6g'},
        complianceStatus: 'warning',
        mfgDate: 'Aug 2026',
        bestBefore: '12 Months',
      );

      final json = product.toJson();
      expect(json['product_name'], 'Choco Crisp Cereal');
      expect(json['mrp'], 199.0);
      expect(product.labelStatusText, 'Potential issue detected');

      final parsed = ProductModel.fromJson(json);
      expect(parsed.id, 'prod-123');
      expect(parsed.ingredients.length, 3);
      expect(parsed.complianceStatus, 'warning');
    });

    test('ConsumerComplaintModel step index and timeline tracking', () {
      final cSubmitted = ConsumerComplaintModel(
        id: 'c-1',
        complaintCode: 'CMP-2026-001284',
        consumerId: 'u-1',
        productName: 'ABC Snacks',
        issueCategory: 'Potential MRP Discrepancy',
        description: 'Dual price sticker',
        status: 'submitted',
        createdAt: DateTime(2026, 8, 27),
      );
      expect(cSubmitted.currentStepIndex, 0);
      expect(cSubmitted.formattedDate, '27 Aug 2026');

      final cUnderReview = ConsumerComplaintModel(
        id: 'c-2',
        complaintCode: 'CMP-2026-001285',
        consumerId: 'u-1',
        productName: 'ABC Snacks',
        issueCategory: 'Potential MRP Discrepancy',
        description: 'Dual price sticker',
        status: 'under_review',
        createdAt: DateTime(2026, 8, 27),
      );
      expect(cUnderReview.currentStepIndex, 1);
      expect(cUnderReview.displayStatus, 'Under Review');

      final cForwarded = ConsumerComplaintModel(
        id: 'c-3',
        complaintCode: 'CMP-2026-001286',
        consumerId: 'u-1',
        productName: 'ABC Snacks',
        issueCategory: 'Potential MRP Discrepancy',
        description: 'Dual price sticker',
        status: 'forwarded_to_company',
        createdAt: DateTime(2026, 8, 27),
      );
      expect(cForwarded.currentStepIndex, 2);
      expect(cForwarded.displayStatus, 'Forwarded to Company');
    });
  });

  group('Consumer Widgets Rendering Tests', () {
    testWidgets('ScanHeroCard renders title, description, and primary Scan Label button', (tester) async {
      bool scanClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanHeroCard(
              onScanPressed: () => scanClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Scan a Product Label'), findsOneWidget);
      expect(find.text('Scan Label'), findsOneWidget);

      await tester.tap(find.text('Scan Label'));
      expect(scanClicked, true);
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

    testWidgets('RecentScansSection renders scan items, status tags, and View Summary CTA', (tester) async {
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
              onScanNewTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Recently Scanned'), findsOneWidget);
      expect(find.text('Artisan Sourdough'), findsOneWidget);
      expect(find.text('Label Check: No obvious issue detected'), findsOneWidget);
      expect(find.text('Choco Crisp'), findsOneWidget);
      expect(find.text('Potential issue detected'), findsOneWidget);
      expect(find.text('View Summary →'), findsNWidgets(2));
    });

    testWidgets('RecentScansSection renders empty state when no scans exist', (tester) async {
      bool scanNewTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentScansSection(
              scans: const [],
              onScanTap: (_) {},
              onViewAllTap: () {},
              onScanNewTap: () => scanNewTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('No products scanned yet'), findsOneWidget);
      expect(
        find.text('Scan your first product to see its ingredients, nutrition and label summary.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Scan Label'));
      expect(scanNewTapped, true);
    });

    testWidgets('MyComplaintsSection renders complaint items, status, and timeline link', (tester) async {
      final dummyComplaints = [
        ConsumerComplaintModel(
          id: 'c-1',
          complaintCode: 'CMP-2026-001284',
          consumerId: 'u-1',
          productName: 'ABC Snacks',
          issueCategory: 'Potential MRP Discrepancy',
          description: 'Dual price sticker',
          status: 'under_review',
          createdAt: DateTime(2026, 8, 27),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyComplaintsSection(
              complaints: dummyComplaints,
              onComplaintTap: (_) {},
              onViewAllTap: () {},
              onReportNewTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('My Complaints'), findsOneWidget);
      expect(find.text('CMP-2026-001284'), findsOneWidget);
      expect(find.text('Under Review'), findsOneWidget);
      expect(find.text('ABC Snacks'), findsOneWidget);
      expect(find.text('Track Timeline →'), findsOneWidget);
    });

    testWidgets('ComplaintDetailModal renders timeline stages and details', (tester) async {
      final complaint = ConsumerComplaintModel(
        id: 'c-1',
        complaintCode: 'CMP-2026-001284',
        consumerId: 'u-1',
        productName: 'ABC Snacks',
        brand: 'XYZ Foods',
        issueCategory: 'Potential MRP Discrepancy',
        description: 'Dual price sticker observed',
        storeLocation: 'City Center Mall',
        status: 'under_review',
        createdAt: DateTime(2026, 8, 27),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComplaintDetailModal(complaint: complaint),
          ),
        ),
      );

      expect(find.text('CMP-2026-001284'), findsOneWidget);
      expect(find.text('ABC Snacks'), findsOneWidget);
      expect(find.text('Location: City Center Mall'), findsOneWidget);
      expect(find.text('Complaint Submitted'), findsOneWidget);
      expect(find.text('Under Review'), findsOneWidget);
      expect(find.text('Forwarded to Company'), findsOneWidget);
    });
  });
}
