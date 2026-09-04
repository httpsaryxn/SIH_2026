import 'dart:async';
import 'file_upload_service.dart';

Future<UploadedFilePayload?> pickFile({required String acceptedTypes}) async {
  // Stub fallback for non-web platforms
  return const UploadedFilePayload(
    name: 'selected_brand_logo.png',
    sizeInBytes: 245000,
    extension: '.png',
  );
}
