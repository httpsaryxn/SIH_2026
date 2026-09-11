import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../models/pending_capture.dart';
import 'camera_capture_service.dart';

/// Service managing real-time hardware and emulator camera feeds,
/// live viewfinder streaming, and direct frame captures.
class LiveCameraService {
  /// Safely queries the device for available cameras.
  /// Returns an empty list if running in an automated test environment,
  /// unsupported platform, or if camera permissions are unavailable.
  static Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      return await availableCameras();
    } catch (e) {
      debugPrint('LiveCameraService: Camera discovery unavailable ($e)');
      return const <CameraDescription>[];
    }
  }

  /// Initializes a [CameraController] for the requested [direction] (default: back).
  /// Returns `null` gracefully if no camera hardware is available or initialization fails.
  static Future<CameraController?> createController({
    CameraLensDirection direction = CameraLensDirection.back,
    ResolutionPreset resolution = ResolutionPreset.high,
  }) async {
    try {
      final cameras = await getAvailableCameras();
      if (cameras.isEmpty) return null;

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == direction,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      return controller;
    } catch (e) {
      debugPrint('LiveCameraService: Error initializing camera controller: $e');
      return null;
    }
  }

  /// Captures a high-resolution snapshot directly from the active [controller]
  /// and saves it to the temporary cache directory as a [PendingCapture].
  static Future<PendingCapture?> snapPicture({
    required CameraController controller,
    required String sourceTag,
  }) async {
    try {
      if (!controller.value.isInitialized || controller.value.isTakingPicture) {
        return null;
      }

      final XFile xFile = await controller.takePicture();
      final bytes = await xFile.readAsBytes();

      return await CameraCaptureService.saveBytesToCache(
        bytes: bytes,
        sourceTag: sourceTag,
      );
    } catch (e) {
      debugPrint('LiveCameraService: Error snapping picture: $e');
      return null;
    }
  }

  /// Safely disposes the given [controller] catching any concurrent release issues.
  static Future<void> disposeController(CameraController? controller) async {
    if (controller == null) return;
    try {
      await controller.dispose();
    } catch (e) {
      debugPrint('LiveCameraService: Error disposing camera controller: $e');
    }
  }
}
