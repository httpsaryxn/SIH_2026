import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/models/pending_capture.dart';
import 'package:mobile/core/services/camera_capture_service.dart';
import 'package:mobile/core/services/storage_service.dart';
import 'package:mobile/screens/regulator/regulator_audit_intake_screen.dart';
import 'package:mobile/screens/consumer/widgets/scanner_modal_sheet.dart';
import 'package:mobile/screens/consumer/consumer_scan_analysis_screen.dart';
import 'package:mobile/screens/regulator/regulator_scan_analysis_screen.dart';

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
      expect(find.text('1.0 MB'), findsOneWidget);
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
      expect(find.text('397.6 KB'), findsOneWidget);
      expect(find.text('Proceed to Legal Review & Case File'), findsOneWidget);
      expect(find.text('Capture Another Sample'), findsOneWidget);
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
}
