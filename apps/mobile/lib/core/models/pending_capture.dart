import 'dart:io';
import 'dart:typed_data';

/// Represents a locally cached image capture ready for processing or backend upload.
class PendingCapture {
  final String localPath;
  final String fileName;
  final DateTime capturedAt;
  final String capturedBySource; // 'regulator_field' | 'consumer_scan' | 'regulator_ecommerce' | 'consumer_gallery'
  final int fileSizeBytes;
  final String? associatedRecordId;
  final Uint8List? rawBytes;

  const PendingCapture({
    required this.localPath,
    required this.fileName,
    required this.capturedAt,
    required this.capturedBySource,
    required this.fileSizeBytes,
    this.associatedRecordId,
    this.rawBytes,
  });

  File get file => File(localPath);

  bool get existsSync {
    try {
      return file.existsSync();
    } catch (_) {
      return false;
    }
  }

  String get formattedSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  PendingCapture copyWith({
    String? localPath,
    String? fileName,
    DateTime? capturedAt,
    String? capturedBySource,
    int? fileSizeBytes,
    String? associatedRecordId,
    Uint8List? rawBytes,
  }) {
    return PendingCapture(
      localPath: localPath ?? this.localPath,
      fileName: fileName ?? this.fileName,
      capturedAt: capturedAt ?? this.capturedAt,
      capturedBySource: capturedBySource ?? this.capturedBySource,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      associatedRecordId: associatedRecordId ?? this.associatedRecordId,
      rawBytes: rawBytes ?? this.rawBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'local_path': localPath,
      'file_name': fileName,
      'captured_at': capturedAt.toIso8601String(),
      'captured_by_source': capturedBySource,
      'file_size_bytes': fileSizeBytes,
      'associated_record_id': associatedRecordId,
    };
  }

  factory PendingCapture.fromJson(Map<String, dynamic> json) {
    return PendingCapture(
      localPath: json['local_path'] as String,
      fileName: json['file_name'] as String,
      capturedAt: DateTime.parse(json['captured_at'] as String),
      capturedBySource: json['captured_by_source'] as String,
      fileSizeBytes: json['file_size_bytes'] as int,
      associatedRecordId: json['associated_record_id'] as String?,
    );
  }

  @override
  String toString() =>
      'PendingCapture(fileName: $fileName, source: $capturedBySource, size: $formattedSize)';
}
