import 'pending_capture.dart';
import 'capture_role.dart';

/// Container for 3 role-specific [PendingCapture] slots.
///
/// Each scan requires up to 3 images:
/// - [frontLabel]: Full front-facing label (PDP area)
/// - [curvedSurface]: Side/curved surface (ingredients, nutrition, manufacturer)
/// - [scaleReference]: Close-up with scale reference for font-height measurement
class MultiCapturePayload {
  PendingCapture? frontLabel;
  PendingCapture? curvedSurface;
  PendingCapture? scaleReference;

  MultiCapturePayload({
    this.frontLabel,
    this.curvedSurface,
    this.scaleReference,
  });

  /// Whether all 3 role-specific captures have been completed.
  bool get isComplete =>
      frontLabel != null && curvedSurface != null && scaleReference != null;

  /// Number of captures completed so far.
  int get capturedCount =>
      [frontLabel, curvedSurface, scaleReference]
          .where((c) => c != null)
          .length;

  /// Whether at least one capture exists (minimum to proceed).
  bool get hasAnyCapture => capturedCount > 0;

  /// Returns all non-null captures as a flat list.
  List<PendingCapture> get allCaptures =>
      [frontLabel, curvedSurface, scaleReference]
          .whereType<PendingCapture>()
          .toList();

  /// Returns a list of (CaptureRole, PendingCapture) pairs for non-null captures.
  List<MapEntry<CaptureRole, PendingCapture>> get capturedEntries {
    final entries = <MapEntry<CaptureRole, PendingCapture>>[];
    if (frontLabel != null) {
      entries.add(MapEntry(CaptureRole.frontLabel, frontLabel!));
    }
    if (curvedSurface != null) {
      entries.add(MapEntry(CaptureRole.curvedSurface, curvedSurface!));
    }
    if (scaleReference != null) {
      entries.add(MapEntry(CaptureRole.scaleReference, scaleReference!));
    }
    return entries;
  }

  /// Gets the capture for a specific [role].
  PendingCapture? getForRole(CaptureRole role) {
    switch (role) {
      case CaptureRole.frontLabel:
        return frontLabel;
      case CaptureRole.curvedSurface:
        return curvedSurface;
      case CaptureRole.scaleReference:
        return scaleReference;
    }
  }

  /// Sets the capture for a specific [role].
  void setForRole(CaptureRole role, PendingCapture? capture) {
    switch (role) {
      case CaptureRole.frontLabel:
        frontLabel = capture;
        break;
      case CaptureRole.curvedSurface:
        curvedSurface = capture;
        break;
      case CaptureRole.scaleReference:
        scaleReference = capture;
        break;
    }
  }

  /// Clears the capture for a specific [role].
  void clearForRole(CaptureRole role) => setForRole(role, null);

  /// The primary display image (first available capture, preferring front label).
  PendingCapture? get primaryCapture =>
      frontLabel ?? curvedSurface ?? scaleReference;

  @override
  String toString() =>
      'MultiCapturePayload(front: ${frontLabel != null}, curved: ${curvedSurface != null}, scale: ${scaleReference != null})';
}
