import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/regulator_data_service.dart';
import 'package:mobile/screens/regulator/regulator_home_screen.dart';
import 'package:mobile/screens/regulator/regulator_audit_intake_screen.dart';
import 'package:mobile/screens/regulator/regulator_violation_review_screen.dart';
import 'package:mobile/screens/regulator/regulator_complaint_inbox_screen.dart';
import 'package:mobile/screens/regulator/regulator_complaint_detail_screen.dart';
import 'package:mobile/screens/regulator/regulator_notice_generator_screen.dart';
import 'package:mobile/screens/regulator/regulator_company_tracking_screen.dart';
import 'package:mobile/screens/regulator/regulator_demo_entry.dart';

final List<int> _transparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpClientRequest();
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();
}

class _FakeHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _FakeHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  List<String>? operator [](String name) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _MockHttpOverrides();

  group('Regulator Data Service & Datasets Validation', () {
    test('getFlaggedViolations returns 8+ varied records', () async {
      final list = await RegulatorDataService.getFlaggedViolations();
      expect(list.length, greaterThanOrEqualTo(8));
      for (final item in list) {
        expect(item.id.isNotEmpty, isTrue);
        expect(item.productName.isNotEmpty, isTrue);
        expect(item.companyName.isNotEmpty, isTrue);
        expect(item.confidenceScore, greaterThan(0));
      }
    });

    test('getComplaints returns 8+ varied records', () async {
      final list = await RegulatorDataService.getComplaints();
      expect(list.length, greaterThanOrEqualTo(8));
      for (final item in list) {
        expect(item.id.isNotEmpty, isTrue);
        expect(item.title.isNotEmpty, isTrue);
        expect(item.locationName.isNotEmpty, isTrue);
      }
    });

    test('getCompanies returns 8+ varied records with timelines', () async {
      final list = await RegulatorDataService.getCompanies();
      expect(list.length, greaterThanOrEqualTo(8));
      for (final item in list) {
        expect(item.id.isNotEmpty, isTrue);
        expect(item.name.isNotEmpty, isTrue);
        expect(item.complianceScore, inInclusiveRange(0, 100));
        expect(item.timeline.isNotEmpty, isTrue);
      }
    });

    test('generateNoticeDraft generates populated Show-Cause notice', () async {
      final notice = await RegulatorDataService.generateNoticeDraft('viol-001');
      expect(notice.id.isNotEmpty, isTrue);
      expect(notice.noticeNumber.isNotEmpty, isTrue);
      expect(notice.ruleCitation.isNotEmpty, isTrue);
      expect(notice.history.isNotEmpty, isTrue);
    });

    test('Violation actions update state properly', () async {
      await RegulatorDataService.confirmViolation('viol-001');
      final viol = await RegulatorDataService.getViolationById('viol-001');
      expect(viol.status, 'confirmed');

      await RegulatorDataService.markFalsePositive('viol-002');
      final viol2 = await RegulatorDataService.getViolationById('viol-002');
      expect(viol2.status, 'false_positive');
    });
  });

  group('Regulator Screens Widget Rendering Tests', () {
    Widget createTestApp(Widget child) {
      return MaterialApp(
        home: child,
      );
    }

    testWidgets('Screen 1 - RegulatorHomeScreen renders overview and priority queue',
        (tester) async {
      await tester.pumpWidget(createTestApp(const RegulatorHomeScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Morning, Officer.'), findsOneWidget);
      expect(find.text('Here is your operational overview for today.'), findsOneWidget);
      expect(find.text('Priority Queue'), findsOneWidget);
      expect(find.text('ITEMS SCANNED'), findsOneWidget);
      expect(find.text('ACTIVE VIOLATIONS'), findsOneWidget);
      expect(find.text('All Active'), findsOneWidget);
    });

    testWidgets('Screen 2 - RegulatorAuditIntakeScreen renders intake tabs and viewfinder',
        (tester) async {
      await tester.pumpWidget(createTestApp(const RegulatorAuditIntakeScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Audit Intake'), findsOneWidget);
      expect(find.text('Field Photo Capture'), findsOneWidget);
      expect(find.text('E-Commerce URL'), findsOneWidget);
      expect(find.text('Scan Packaging Label'), findsOneWidget);
    });

    testWidgets('Screen 3 - RegulatorViolationReviewScreen renders declarations and actions',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        const RegulatorViolationReviewScreen(violationId: 'viol-001'),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Review Violation'), findsOneWidget);
      expect(find.text('Extracted Declarations'), findsOneWidget);
      expect(find.text('Confirm Violation'), findsOneWidget);
      expect(find.text('Mark False Positive'), findsOneWidget);
      expect(find.text('Escalate'), findsOneWidget);
    });

    testWidgets('Screen 4 - RegulatorComplaintInboxScreen renders tabs and complaints',
        (tester) async {
      await tester.pumpWidget(createTestApp(const RegulatorComplaintInboxScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Unified Intake Queue'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Submitted'), findsWidgets);
      expect(find.text('Under Review'), findsWidgets);
    });

    testWidgets('Screen 5 - RegulatorComplaintDetailScreen renders evidence and actions',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        const RegulatorComplaintDetailScreen(complaintId: 'cmp-001'),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Complaint Details'), findsOneWidget);
      expect(find.text('Evidence Photos'), findsOneWidget);
      expect(find.text('Consumer Report'), findsOneWidget);
      expect(find.text('Location Data'), findsOneWidget);
      expect(find.text('Verify & Forward'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('Screen 6 - RegulatorNoticeGeneratorScreen renders notice draft form',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        const RegulatorNoticeGeneratorScreen(violationId: 'viol-001'),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Notice Draft'), findsOneWidget);
      expect(find.text('Response Deadline'), findsOneWidget);
      expect(find.text('Entity History'), findsOneWidget);
      expect(find.text('Issue Formal Notice'), findsOneWidget);
    });

    testWidgets('Screen 7 - RegulatorCompanyTrackingScreen renders search and companies',
        (tester) async {
      await tester.pumpWidget(createTestApp(const RegulatorCompanyTrackingScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Violations & Enforcement History'), findsOneWidget);
      expect(find.text('My Actions'), findsOneWidget);
      expect(find.text('Company Compliance'), findsOneWidget);
    });

    testWidgets('Demo Entry Screen renders links to all 7 screens',
        (tester) async {
      await tester.pumpWidget(createTestApp(const RegulatorDemoEntry()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Regulator Module Demo Hub'), findsOneWidget);
      expect(find.text('Officer Home Overview'), findsOneWidget);
      expect(find.text('Scan / Audit Intake'), findsOneWidget);
      expect(find.text('Violation Review Queue'), findsOneWidget);
      expect(find.text('Consumer Complaint Inbox'), findsOneWidget);
      expect(find.text('Complaint Details'), findsOneWidget);
      expect(find.text('Notice & Action Generator'), findsOneWidget);
      expect(find.text('Company & Case Tracking'), findsOneWidget);
    });

    testWidgets('Bottom Nav Bar switches to Violations, Inbox, and Audit tabs on tap',
        (tester) async {
      await tester.pumpWidget(createTestApp(const RegulatorHomeScreen()));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // 1. Tap Violations tab
      await tester.tap(find.widgetWithText(InkWell, 'Violations'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Violations & Enforcement History'), findsOneWidget);

      // 2. Tap Inbox tab from Company Tracking screen
      await tester.tap(find.widgetWithText(InkWell, 'Inbox'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Unified Intake Queue'), findsOneWidget);

      // 3. Tap Audit tab from Inbox screen
      await tester.tap(find.widgetWithText(InkWell, 'Audit'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Audit Intake'), findsOneWidget);

      // 4. Tap Home tab to return to Home Overview
      await tester.tap(find.widgetWithText(InkWell, 'Home'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Morning, Officer.'), findsOneWidget);
    });

    testWidgets('Pulling down on list does not stretch or break fixed header',
        (tester) async {
      await tester.pumpWidget(createTestApp(const RegulatorHomeScreen()));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify header is mounted
      expect(find.text('Morning, Officer.'), findsOneWidget);

      // Simulate pull-down overscroll drag
      await tester.drag(find.text('Morning, Officer.'), const Offset(0, 300));
      await tester.pump(const Duration(milliseconds: 100));

      // Header remains intact and displayed
      expect(find.text('Morning, Officer.'), findsOneWidget);
    });
  });
}
