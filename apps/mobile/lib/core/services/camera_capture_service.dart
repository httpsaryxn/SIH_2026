import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/pending_capture.dart';

/// Central service for capturing photos, caching them to the app temp directory,
/// and packaging them into backend-ready PendingCapture payloads.
class CameraCaptureService {
  static final ImagePicker _defaultPicker = ImagePicker();

  /// Captures an image from the camera (or gallery), saves it to the local cache directory,
  /// and returns a PendingCapture object.
  static Future<PendingCapture?> captureImage({
    required BuildContext context,
    required String sourceTag,
    ImageSource imageSource = ImageSource.camera,
    ImagePicker? customPicker,
    Directory? customTempDirectory,
  }) async {
    final picker = customPicker ?? _defaultPicker;

    try {
      final XFile? pickedFile = await picker.pickImage(
        source: imageSource,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      // User cancelled camera / picker cleanly
      if (pickedFile == null) {
        debugPrint('CameraCaptureService: Capture cancelled by user.');
        return null;
      }

      final bytes = await pickedFile.readAsBytes();
      final tempDir = customTempDirectory ?? await getTemporaryDirectory();

      // Collision-safe filename: scan_<source>_<timestamp>_<randomHex>.jpg
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = _generateRandomHex(6);
      final fileName = 'scan_${sourceTag}_${timestamp}_$randomSuffix.jpg';
      final cachePath = '${tempDir.path}/$fileName';

      final cachedFile = File(cachePath);
      await cachedFile.writeAsBytes(bytes);

      debugPrint('CameraCaptureService: Saved cache file at $cachePath (${bytes.length} bytes)');

      return PendingCapture(
        localPath: cachePath,
        fileName: fileName,
        capturedAt: DateTime.now(),
        capturedBySource: sourceTag,
        fileSizeBytes: bytes.length,
        rawBytes: bytes,
      );
    } on PlatformException catch (e) {
      debugPrint('CameraCaptureService: Platform error during capture: ${e.code} - ${e.message}');
      if (context.mounted) {
        _showPermissionDeniedFeedback(context, imageSource, sourceTag);
      }
      return null;
    } catch (e) {
      debugPrint('CameraCaptureService: Unexpected error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not complete photo capture: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }

  static void _showPermissionDeniedFeedback(
    BuildContext context,
    ImageSource source,
    String sourceTag,
  ) {
    final sourceName = source == ImageSource.camera ? 'Camera' : 'Photos / Gallery';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$sourceName access is required to capture packaging labels.'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () {
            captureImage(
              context: context,
              sourceTag: sourceTag,
              imageSource: source,
            );
          },
        ),
      ),
    );
  }

  static String _generateRandomHex(int length) {
    final random = Random();
    const chars = 'abcdef0123456789';
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
