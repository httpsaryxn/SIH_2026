import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pending_capture.dart';
import '../models/capture_role.dart';
import '../models/multi_capture_payload.dart';
import 'auth_service.dart';

/// Service responsible for uploading locally cached [PendingCapture] images
/// to Supabase Storage ('compliance-images' private bucket) with structured paths
/// and generating accessible signed URLs for the database.
class StorageService {
  static SupabaseClient get _client => Supabase.instance.client;

  static const String bucketName = 'compliance-images';

  /// Builds a structured path in the format:
  /// `{source}/{user_id}/{record_id}/{filename}`
  ///
  /// Examples:
  /// - `regulator_scans/a812.../SCN-2026-001/scan_regulator_field_178819...jpg`
  /// - `consumer_scans/b415.../s-prod-987/scan_consumer_scan_178819...jpg`
  /// - `consumer_complaints/b415.../CMP-2026-104928/scan_consumer_scan_...jpg`
  static String buildStoragePath({
    required String source,
    required String userId,
    required String recordId,
    required String fileName,
  }) {
    final cleanSource = source.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final cleanUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final cleanRecordId = recordId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_\.\-]'), '_');

    return '$cleanSource/$cleanUserId/$cleanRecordId/$cleanFileName';
  }

  /// Uploads a [PendingCapture] to Supabase Storage at a structured path.
  /// 
  /// Returns the signed URL (valid for 1 year) or public path on success,
  /// or null if upload fails.
  /// 
  /// NOTE: This does NOT delete the local cached file. Local cache cleanup
  /// must only happen via [deleteLocalCacheAfterSync] after confirmed database row persistence.
  static Future<String?> uploadPendingCapture({
    required PendingCapture pendingCapture,
    required String source,
    required String recordId,
    String? customUserId,
    SupabaseClient? customClient,
  }) async {
    try {
      if (!pendingCapture.existsSync) {
        return null;
      }

      final fileBytes = await pendingCapture.file.readAsBytes();
      if (fileBytes.isEmpty) return null;

      final client = customClient ?? _client;
      final userId = customUserId ?? AuthService.currentUser?.id ?? 'guest_user';
      final storagePath = buildStoragePath(
        source: source,
        userId: userId,
        recordId: recordId,
        fileName: pendingCapture.fileName,
      );

      // 1. Upload bytes to Supabase Storage
      await client.storage.from(bucketName).uploadBinary(
        storagePath,
        fileBytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      // 2. Generate signed URL for private bucket access (1 year duration)
      try {
        final signedUrl = await client.storage.from(bucketName).createSignedUrl(
          storagePath,
          60 * 60 * 24 * 365,
        );
        return signedUrl;
      } catch (_) {
        // Fallback: return storage path if signed URL creation encounters issues
        return storagePath;
      }
    } catch (e) {
      // Graceful error recovery: Keep local cached file intact for retry
      return null;
    }
  }

  /// Safely removes the local cached image file ONLY after confirmed DB write.
  static Future<bool> deleteLocalCacheAfterSync(PendingCapture capture) async {
    try {
      if (capture.existsSync) {
        await capture.file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Uploads all captures in a [MultiCapturePayload] in parallel.
  ///
  /// Returns a map of [CaptureRole] → signed URL for each successfully uploaded image.
  /// Roles with null captures are skipped.
  static Future<Map<CaptureRole, String?>> uploadMultiCapture({
    required MultiCapturePayload payload,
    required String source,
    required String recordId,
    String? customUserId,
  }) async {
    final results = <CaptureRole, String?>{};

    // Build list of upload futures in parallel
    final futures = <Future<MapEntry<CaptureRole, String?>>>[];

    for (final role in CaptureRoleInfo.orderedRoles) {
      final capture = payload.getForRole(role);
      if (capture == null || !capture.existsSync) {
        results[role] = null;
        continue;
      }

      futures.add(
        uploadPendingCapture(
          pendingCapture: capture,
          source: source,
          recordId: '$recordId/${role.name}',
          customUserId: customUserId,
        ).then((url) => MapEntry(role, url)),
      );
    }

    // Await all uploads in parallel
    final uploadResults = await Future.wait(futures);
    for (final entry in uploadResults) {
      results[entry.key] = entry.value;
    }

    return results;
  }

  /// Deletes all local cached files in a [MultiCapturePayload] after confirmed DB sync.
  static Future<void> deleteMultiCaptureLocalCache(MultiCapturePayload payload) async {
    for (final capture in payload.allCaptures) {
      await deleteLocalCacheAfterSync(capture);
    }
  }
}
