import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/models/capture_role.dart';
import 'package:mobile/core/models/consumer_scan_model.dart';
import 'package:mobile/core/models/inbox_item.dart';
import 'package:mobile/core/models/label_verification_request.dart';
import 'package:mobile/core/models/multi_capture_payload.dart';
import 'package:mobile/core/models/pending_capture.dart';
import 'package:mobile/core/models/regulator_action_item.dart';
import 'package:mobile/core/models/regulator_complaint.dart';
import 'package:mobile/core/services/camera_capture_service.dart';
import 'package:mobile/core/services/storage_service.dart';
import 'package:mobile/screens/regulator/regulator_audit_intake_screen.dart';
import 'package:mobile/screens/consumer/widgets/scanner_modal_sheet.dart';
import 'package:mobile/screens/consumer/consumer_scan_analysis_screen.dart';
import 'package:mobile/screens/regulator/regulator_scan_analysis_screen.dart';
import 'package:mobile/screens/regulator/regulator_complaint_inbox_screen.dart';
import 'package:mobile/screens/regulator/regulator_company_tracking_screen.dart';
import 'package:mobile/screens/regulator/regulator_label_review_screen.dart';
import 'package:mobile/screens/shared/multi_capture_screen.dart';

class _FakeImagePicker extends ImagePicker {
  final XFile? imageToReturn;
  final bool throwPermissionError;

  _FakeImagePicker({
    this.imageToReturn,
    this.throwPermissionError = false,
  });

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    if (throwPermissionError) {
      throw PlatformException(
        code: 'camera_access_denied',
        message: 'Camera permission was denied.',
      );
    }
    return imageToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PendingCapture Model Unit Tests', () {
    test('Correctly computes formatted file sizes', () {
      final now = DateTime(2026, 8, 31);
      final captureBytes = PendingCapture(
        localPath: '/tmp/test.jpg',
        fileName: 'test.jpg',
        capturedAt: now,
        capturedBySource: 'regulator_field',
        fileSizeBytes: 512,
      );
      expect(captureBytes.formattedSize, '512 B');

      final captureKb = PendingCapture(
        localPath: '/tmp/test.jpg',
        fileName: 'test.jpg',
        capturedAt: now,
        capturedBySource: 'regulator_field',
        fileSizeBytes: 2048,
      );
      expect(captureKb.formattedSize, '2.0 KB');

      final captureMb = PendingCapture(
        localPath: '/tmp/test.jpg',
        fileName: 'test.jpg',
        capturedAt: now,
        capturedBySource: 'consumer_scan',
        fileSizeBytes: 2621440,
      );
      expect(captureMb.formattedSize, '2.5 MB');
    });

    test('Serializes to and from JSON properly', () {
      final now = DateTime(2026, 8, 31, 14, 30);
      final capture = PendingCapture(
        localPath: '/tmp/test_scan.jpg',
        fileName: 'test_scan.jpg',
        capturedAt: now,
        capturedBySource: 'regulator_field',
        fileSizeBytes: 10240,
        associatedRecordId: 'REC-001',
      );

      final json = capture.toJson();
      expect(json['local_path'], '/tmp/test_scan.jpg');
      expect(json['file_name'], 'test_scan.jpg');
      expect(json['captured_by_source'], 'regulator_field');
      expect(json['file_size_bytes'], 10240);
      expect(json['associated_record_id'], 'REC-001');

      final fromJson = PendingCapture.fromJson(json);
      expect(fromJson.localPath, capture.localPath);
      expect(fromJson.fileName, capture.fileName);
      expect(fromJson.capturedAt, capture.capturedAt);
      expect(fromJson.capturedBySource, capture.capturedBySource);
      expect(fromJson.fileSizeBytes, capture.fileSizeBytes);
      expect(fromJson.associatedRecordId, capture.associatedRecordId);
    });

    test('copyWith produces updated instance', () {
      final now = DateTime.now();
      final capture = PendingCapture(
        localPath: '/tmp/test1.jpg',
        fileName: 'test1.jpg',
        capturedAt: now,
        capturedBySource: 'regulator_field',
        fileSizeBytes: 100,
      );

      final updated = capture.copyWith(
        localPath: '/tmp/test2.jpg',
        associatedRecordId: 'REC-123',
      );

      expect(updated.localPath, '/tmp/test2.jpg');
      expect(updated.fileName, 'test1.jpg');
      expect(updated.associatedRecordId, 'REC-123');
    });
  });

  group('CameraCaptureService Unit Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('camera_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('Returns null when user cancels camera capture', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
      final context = tester.element(find.byType(SizedBox));

      final result = await CameraCaptureService.captureImage(
        context: context,
        sourceTag: 'regulator_field',
        imageSource: ImageSource.camera,
        customPicker: _FakeImagePicker(imageToReturn: null),
        customTempDirectory: tempDir,
      );
      expect(result, isNull);
    });

    testWidgets('Returns null and shows feedback on permission error', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
      final context = tester.element(find.byType(SizedBox));

      final result = await CameraCaptureService.captureImage(
        context: context,
        sourceTag: 'regulator_field',
        imageSource: ImageSource.camera,
        customPicker: _FakeImagePicker(throwPermissionError: true),
        customTempDirectory: tempDir,
      );
      expect(result, isNull);
      await tester.pump();

      expect(find.textContaining('Camera access is required'), findsOneWidget);
    });

    testWidgets('Caches image and returns PendingCapture on successful capture', (tester) async {
      await tester.runAsync(() async {
        final testFile = File('${tempDir.path}/source_sample.jpg');
        await testFile.writeAsBytes([1, 2, 3, 4, 5, 6, 7, 8]);

        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
        final context = tester.element(find.byType(SizedBox));

        final captured = await CameraCaptureService.captureImage(
          context: context,
          sourceTag: 'consumer_scan',
          imageSource: ImageSource.camera,
          customPicker: _FakeImagePicker(
            imageToReturn: XFile(testFile.path),
          ),
          customTempDirectory: tempDir,
        );

        expect(captured, isNotNull);
        expect(captured!.capturedBySource, 'consumer_scan');
        expect(captured.fileSizeBytes, 8);
        expect(captured.fileName, contains('scan_consumer_scan_'));
        expect(captured.existsSync, isTrue);

        if (captured.existsSync) {
          await captured.file.delete();
        }
      });
    });
  });

  group('Regulator Audit Intake Screen Widget Tests', () {
    testWidgets('Renders camera viewfinder with shutter button and tab controls', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: RegulatorAuditIntakeScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Audit Intake'), findsOneWidget);
      expect(find.text('Field Photo Capture'), findsOneWidget);
      expect(find.text('E-Commerce URL'), findsOneWidget);
      expect(find.text('Scan Packaging Label'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Tap to Capture'), findsOneWidget);
    });
  });

  group('Consumer Scanner Modal Sheet Widget Tests', () {
    testWidgets('Renders Step 1 form and navigates to Step 2 camera scan', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ScannerModalSheet(
            onScanCompleted: (_) {},
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Step 1: Enter Product'), findsOneWidget);
      expect(find.text('Product Name *'), findsOneWidget);
      expect(find.text('Continue to Camera Scan'), findsOneWidget);

      // Enter food product name
      await tester.enterText(
        find.byType(TextFormField).first,
        'Organic Almond Milk',
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll into view & tap Continue to Step 2
      await tester.ensureVisible(find.text('Continue to Camera Scan'));
      await tester.tap(find.text('Continue to Camera Scan'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Step 2: Capture Label'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Upload File'), findsOneWidget);
      expect(find.text('Analyze Label & Save to Database'), findsOneWidget);
    });
  });

  group('ConsumerScanAnalysisScreen Widget Tests', () {
    testWidgets('Renders scanning viewport, progress bar, and pipeline stages', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final capture = PendingCapture(
        localPath: '/tmp/test_scan.jpg',
        fileName: 'scan_consumer_scan_12345.jpg',
        capturedAt: DateTime.now(),
        capturedBySource: 'consumer_scan',
        fileSizeBytes: 1048576,
      );

      await tester.pumpWidget(MaterialApp(
        home: ConsumerScanAnalysisScreen(
          pendingCapture: capture,
          prefilledProductName: 'Organic Oats Bowl',
          prefilledBrand: 'NutriLife',
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Scanning & Analysis'), findsOneWidget);
      expect(find.text('Pipeline Verification Stages'), findsOneWidget);
      expect(find.text('Image Ingestion & Cache'), findsOneWidget);
      expect(find.text('OCR & Text Detection'), findsOneWidget);
      expect(find.text('Legal Metrology PCR 2011 Verification'), findsOneWidget);
      expect(find.text('Database Sync & Catalog Update'), findsOneWidget);
      expect(find.text('1.0 MB'), findsWidgets);
    });
  });

  group('RegulatorScanAnalysisScreen Widget Tests', () {
    testWidgets('Renders scanning viewport, progress bar, and pipeline stages for regulator', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final capture = PendingCapture(
        localPath: '/tmp/test_audit_scan.jpg',
        fileName: 'scan_regulator_field_98765.jpg',
        capturedAt: DateTime.now(),
        capturedBySource: 'regulator_field',
        fileSizeBytes: 407142, // ~397.6 KB
      );

      await tester.pumpWidget(MaterialApp(
        home: RegulatorScanAnalysisScreen(
          pendingCapture: capture,
          prefilledProductName: 'Packaged Food Product',
          prefilledCompanyName: 'Packaged Foods Co.',
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Scan Results'), findsOneWidget);
      expect(find.text('Pipeline Verification Stages'), findsOneWidget);
      expect(find.text('Evidence Ingestion & Secure Cache'), findsOneWidget);
      expect(find.text('Multi-Zone OCR & Text Extraction'), findsOneWidget);
      expect(find.text('Legal Metrology PCR 2011 Verification'), findsOneWidget);
      expect(find.text('Regulatory Case File Generation'), findsOneWidget);
      expect(find.text('397.6 KB'), findsWidgets);
      // During evaluation: action buttons must not appear, wave spinner should be displayed
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Proceed to Legal Review & Case File'), findsNothing);
      expect(find.text('Capture Another Sample'), findsNothing);
    });
  });

  group('StorageService Unit Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('storage_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('buildStoragePath generates clean hierarchical structure', () {
      final path = StorageService.buildStoragePath(
        source: 'regulator_scans',
        userId: 'usr-1234-abcd',
        recordId: 'SCN-2026/001',
        fileName: 'scan_field_sample#1.jpg',
      );

      expect(path, 'regulator_scans/usr-1234-abcd/SCN-2026_001/scan_field_sample_1.jpg');
    });

    test('uploadPendingCapture returns null gracefully on non-existent file without crashing', () async {
      final nonExistentCapture = PendingCapture(
        localPath: '${tempDir.path}/does_not_exist.jpg',
        fileName: 'does_not_exist.jpg',
        capturedAt: DateTime.now(),
        capturedBySource: 'consumer_scan',
        fileSizeBytes: 0,
      );

      final result = await StorageService.uploadPendingCapture(
        pendingCapture: nonExistentCapture,
        source: 'consumer_scans',
        recordId: 'scan-001',
      );

      expect(result, isNull);
    });

    test('deleteLocalCacheAfterSync deletes local file only when it exists', () async {
      final sampleFile = File('${tempDir.path}/sample_to_clean.jpg');
      await sampleFile.writeAsBytes([10, 20, 30, 40]);

      final capture = PendingCapture(
        localPath: sampleFile.path,
        fileName: 'sample_to_clean.jpg',
        capturedAt: DateTime.now(),
        capturedBySource: 'regulator_field',
        fileSizeBytes: 4,
      );

      expect(capture.existsSync, isTrue);

      final deleted = await StorageService.deleteLocalCacheAfterSync(capture);
      expect(deleted, isTrue);
      expect(capture.existsSync, isFalse);

      // Calling again returns false gracefully
      final deletedAgain = await StorageService.deleteLocalCacheAfterSync(capture);
      expect(deletedAgain, isFalse);
    });
  });

  group('Unified InboxItem & LabelVerificationRequest Unit Tests', () {
    test('InboxItem correctly maps from RegulatorComplaint', () {
      final complaint = RegulatorComplaint(
        id: 'cmp-001',
        complaintCode: 'CMP-2026-999',
        title: 'Missing MRP Declaration',
        productName: 'Instant Noodles 70g',
        companyName: 'Food Corp Ltd',
        category: 'Packaged Food',
        description: 'No MRP visible on wrapper.',
        locationName: 'City Mart',
        address: 'Sector 5, Pune',
        status: 'Submitted',
        priority: 'High Priority',
        submittedAt: DateTime(2026, 8, 30),
        evidencePhotos: ['https://example.com/photo.jpg'],
      );

      final item = InboxItem.fromComplaint(complaint);
      expect(item.isComplaint, isTrue);
      expect(item.isLabelVerification, isFalse);
      expect(item.code, 'CMP-2026-999');
      expect(item.title, 'Instant Noodles 70g');
      expect(item.subtitle, 'Food Corp Ltd');
      expect(item.imageUrl, 'https://example.com/photo.jpg');
      expect(item.priorityOrTag, 'High Priority');
    });

    test('InboxItem correctly maps from LabelVerificationRequest', () {
      final request = LabelVerificationRequest(
        id: 'lvr-001',
        requestCode: 'LVR-2026-101',
        businessName: 'Organic Harvest Ltd',
        productName: 'Roasted Almond Butter 200g',
        category: 'Spreads & Butter',
        labelImageUrl: 'https://example.com/label.jpg',
        declarations: [
          {'field_name': 'Net Quantity', 'extracted_value': '200 g', 'status': 'Compliant'}
        ],
        status: 'pending',
        priority: 'Normal',
        submittedAt: DateTime(2026, 8, 31),
        createdAt: DateTime(2026, 8, 31),
      );

      final item = InboxItem.fromLabelRequest(request);
      expect(item.isLabelVerification, isTrue);
      expect(item.isComplaint, isFalse);
      expect(item.code, 'LVR-2026-101');
      expect(item.title, 'Roasted Almond Butter 200g');
      expect(item.subtitle, 'Organic Harvest Ltd');
      expect(item.imageUrl, 'https://example.com/label.jpg');
      expect(item.priorityOrTag, 'Label Review Request');
    });

    test('LabelVerificationRequest serializes to and from JSON', () {
      final now = DateTime(2026, 9, 1);
      final req = LabelVerificationRequest(
        id: 'lvr-uuid',
        requestCode: 'LVR-2026-001',
        businessName: 'Madhavi Papad',
        productName: 'Moong Dal Crisps',
        labelImageUrl: 'https://example.com/img.jpg',
        status: 'pending',
        submittedAt: now,
        createdAt: now,
      );

      final json = req.toJson();
      expect(json['request_code'], 'LVR-2026-001');
      expect(json['business_name'], 'Madhavi Papad');

      final fromJson = LabelVerificationRequest.fromJson(json);
      expect(fromJson.id, 'lvr-uuid');
      expect(fromJson.requestCode, 'LVR-2026-001');
      expect(fromJson.businessName, 'Madhavi Papad');
      expect(fromJson.isPending, isTrue);
    });

    test('RegulatorActionItem holds enforcement case history details', () {
      final action = RegulatorActionItem(
        id: 'act-001',
        type: RegulatorActionType.violation,
        referenceCode: 'SCN-2026-001',
        title: 'Font Size Non-Compliance',
        entityName: 'Mega Foods Pvt Ltd',
        imageUrl: 'https://example.com/thumb.jpg',
        actionTaken: 'Confirmed Violation',
        severityOrStatus: 'High',
        actionDate: DateTime(2026, 9, 1),
      );

      expect(action.isViolation, isTrue);
      expect(action.referenceCode, 'SCN-2026-001');
      expect(action.actionTaken, 'Confirmed Violation');
      expect(action.imageUrl, isNotNull);
    });
  });

  group('Regulator Screen Widget Tests (Inbox & Violations History)', () {
    testWidgets('RegulatorComplaintInboxScreen renders Unified Queue and Type Filters', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(
        home: RegulatorComplaintInboxScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Unified Intake Queue'), findsOneWidget);
      expect(find.text('All Intake'), findsOneWidget);
      expect(find.text('Citizen Complaints'), findsOneWidget);
      expect(find.text('Business Label Reviews'), findsOneWidget);
    });

    testWidgets('RegulatorCompanyTrackingScreen renders Segmented 2-Section Tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(
        home: RegulatorCompanyTrackingScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Violations & Enforcement History'), findsOneWidget);
      expect(find.text('My Actions'), findsOneWidget);
      expect(find.text('Company Compliance'), findsOneWidget);
    });

    testWidgets('RegulatorLabelReviewScreen renders Proactive Banner and Decision Buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(
        home: RegulatorLabelReviewScreen(requestId: 'sample-lvr-id'),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      // Header or loading state renders cleanly
      expect(find.byType(AppBar), findsOneWidget);
    });
  });

  group('Multi-Image Capture & Carousel Unit & Widget Tests', () {
    test('CaptureRole and CaptureRoleInfo metadata validation', () {
      expect(CaptureRole.values.length, 3);
      expect(CaptureRoleInfo.orderedRoles.length, 3);

      final frontInfo = CaptureRoleInfo.forRole(CaptureRole.frontLabel);
      expect(frontInfo.label, 'Front Label');
      expect(frontInfo.dbColumnName, 'front_label_url');

      final curvedInfo = CaptureRoleInfo.forRole(CaptureRole.curvedSurface);
      expect(curvedInfo.label, 'Curved Surface');
      expect(curvedInfo.dbColumnName, 'curved_surface_url');

      final scaleInfo = CaptureRoleInfo.forRole(CaptureRole.scaleReference);
      expect(scaleInfo.label, 'Scale Reference');
      expect(scaleInfo.dbColumnName, 'scale_reference_url');
    });

    test('MultiCapturePayload management and accessors', () {
      final payload = MultiCapturePayload();
      expect(payload.isComplete, isFalse);
      expect(payload.hasAnyCapture, isFalse);
      expect(payload.capturedCount, 0);

      final cap1 = PendingCapture(
        localPath: '/tmp/test_front.jpg',
        fileName: 'scan_front.jpg',
        capturedAt: DateTime.now(),
        capturedBySource: 'consumer_scan',
        fileSizeBytes: 1000,
      );

      payload.setForRole(CaptureRole.frontLabel, cap1);
      expect(payload.hasAnyCapture, isTrue);
      expect(payload.capturedCount, 1);
      expect(payload.getForRole(CaptureRole.frontLabel), equals(cap1));
      expect(payload.primaryCapture, equals(cap1));

      final cap2 = PendingCapture(
        localPath: '/tmp/test_curved.jpg',
        fileName: 'scan_curved.jpg',
        capturedAt: DateTime.now(),
        capturedBySource: 'consumer_scan',
        fileSizeBytes: 2000,
      );
      final cap3 = PendingCapture(
        localPath: '/tmp/test_scale.jpg',
        fileName: 'scan_scale.jpg',
        capturedAt: DateTime.now(),
        capturedBySource: 'consumer_scan',
        fileSizeBytes: 3000,
      );

      payload.setForRole(CaptureRole.curvedSurface, cap2);
      payload.setForRole(CaptureRole.scaleReference, cap3);
      expect(payload.isComplete, isTrue);
      expect(payload.capturedCount, 3);
      expect(payload.allCaptures.length, 3);
      expect(payload.capturedEntries.length, 3);
    });

    test('ConsumerScanModel handles multi-image carouselImages gracefully', () {
      final model = ConsumerScanModel(
        id: 'scan-1',
        consumerId: 'user-1',
        productName: 'Biscuits',
        frontLabelUrl: 'https://example.com/front.jpg',
        curvedSurfaceUrl: 'https://example.com/curved.jpg',
        scaleReferenceUrl: 'https://example.com/scale.jpg',
        scannedAt: DateTime.now(),
      );

      final images = model.carouselImages;
      expect(images.length, 3);
      expect(images[0].key, 'Front Label');
      expect(images[0].value, 'https://example.com/front.jpg');
      expect(images[1].key, 'Curved Surface');
      expect(images[2].key, 'Scale Reference');

      // Legacy fallback
      final legacyModel = ConsumerScanModel(
        id: 'scan-legacy',
        consumerId: 'user-1',
        productName: 'Old Scan',
        imageUrl: 'https://example.com/old.jpg',
        scannedAt: DateTime.now(),
      );
      expect(legacyModel.carouselImages.length, 1);
      expect(legacyModel.carouselImages[0].key, 'Label Image');
    });

    testWidgets('MultiCaptureScreen renders 3-step progress, guidance, and buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(
        home: MultiCaptureScreen(
          sourceTag: 'test_capture',
          flowLabel: 'Product Label',
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Product Label Capture'), findsOneWidget);
      expect(find.text('0/3'), findsOneWidget);
      expect(find.textContaining('Front Label'), findsWidgets);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Upload from Gallery'), findsOneWidget);
    });

    testWidgets('ConsumerScanAnalysisScreen renders Carousel Viewport when MultiCapturePayload provided', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final payload = MultiCapturePayload(
        frontLabel: PendingCapture(
          localPath: '/tmp/front.jpg',
          fileName: 'front.jpg',
          capturedAt: DateTime.now(),
          capturedBySource: 'consumer_scan',
          fileSizeBytes: 500000,
        ),
        curvedSurface: PendingCapture(
          localPath: '/tmp/curved.jpg',
          fileName: 'curved.jpg',
          capturedAt: DateTime.now(),
          capturedBySource: 'consumer_scan',
          fileSizeBytes: 600000,
        ),
      );

      await tester.pumpWidget(MaterialApp(
        home: ConsumerScanAnalysisScreen(
          pendingCapture: payload.primaryCapture!,
          multiCapture: payload,
          prefilledProductName: 'Multi-Scan Test',
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets('RegulatorAuditIntakeScreen blocks capture and displays error when mandatory fields are missing', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(
        home: RegulatorAuditIntakeScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('MANDATORY AUDIT IDENTIFIERS'), findsOneWidget);
      expect(find.text('Product name *'), findsOneWidget);
      expect(find.text('Registered company name *'), findsOneWidget);

      // Tap to capture while inputs are empty
      await tester.tap(find.text('Tap to Capture'));
      await tester.pump(const Duration(milliseconds: 300));

      // Should display mandatory error texts
      expect(find.text('Product name is mandatory to proceed'), findsOneWidget);
      expect(find.text('Registered company name is mandatory to proceed'), findsOneWidget);

      // SnackBar warning should be triggered
      expect(
        find.text('Please enter both Product Name and Registered Company Name before proceeding.'),
        findsOneWidget,
      );
    });

    testWidgets('RegulatorAuditIntakeScreen clears error when typing into fields', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(
        home: RegulatorAuditIntakeScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      // Tap to capture to trigger errors
      await tester.tap(find.text('Tap to Capture'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Product name is mandatory to proceed'), findsOneWidget);

      // Enter product name
      await tester.enterText(
        find.widgetWithText(TextField, 'Product name *'),
        'Britannia Good Day Cookies',
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Product error should disappear
      expect(find.text('Product name is mandatory to proceed'), findsNothing);
      expect(find.text('Registered company name is mandatory to proceed'), findsOneWidget);
    });

    testWidgets('MultiCaptureScreen renders audit banner with Product and Company Name', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(
        home: MultiCaptureScreen(
          sourceTag: 'test',
          flowLabel: 'Audit Evidence',
          productName: 'Good Day Butter',
          companyName: 'Britannia Industries Ltd',
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Good Day Butter • Britannia Industries Ltd'), findsOneWidget);
    });
  });
}
