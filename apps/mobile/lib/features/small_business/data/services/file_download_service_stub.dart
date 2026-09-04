import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Resolves the most appropriate persistent Exports or Documents folder
Future<String> _getDownloadDirectoryPath() async {
  // 1. On Android: use the app's dedicated external storage files directory
  // This directory (/storage/emulated/0/Android/data/<package>/files/Exports)
  // requires zero special permissions and is NEVER deleted by Android MediaProvider.
  if (Platform.isAndroid) {
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final exportsDir = Directory('${extDir.path}/Exports');
        if (!await exportsDir.exists()) {
          await exportsDir.create(recursive: true);
        }
        return exportsDir.path;
      }
    } catch (e) {
      debugPrint('Android getExternalStorageDirectory note: $e');
    }
  }

  // 2. On desktop platforms (Windows, macOS, Linux): use system Downloads folder
  if (!Platform.isAndroid && !Platform.isIOS) {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null && await downloadsDir.exists()) {
        return downloadsDir.path;
      }
    } catch (_) {}
  }

  // 3. Fallback: application documents directory
  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${appDocDir.path}/Exports');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    return exportsDir.path;
  } catch (_) {}

  return Directory.systemTemp.path;
}

Future<String?> triggerDownload({
  required String fileName,
  required String content,
  required String mimeType,
  bool shareOnMobile = true,
}) async {
  try {
    final dirPath = await _getDownloadDirectoryPath();
    final file = File('$dirPath/$fileName');
    await file.writeAsString(content, encoding: utf8, flush: true);
    debugPrint('File saved directly to: ${file.path}');

    if (shareOnMobile && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await Share.shareXFiles(
          [XFile(file.path, mimeType: mimeType, name: fileName)],
          text: 'Exported packaging label artwork: $fileName',
          subject: fileName,
        );
      } catch (e) {
        debugPrint('Auto-share error: $e');
      }
    }

    return file.path;
  } catch (e) {
    debugPrint('Error writing file on device, falling back to temp: $e');
    try {
      final fallbackFile = File('${Directory.systemTemp.path}/$fileName');
      await fallbackFile.writeAsString(content, encoding: utf8, flush: true);
      if (shareOnMobile && (Platform.isAndroid || Platform.isIOS)) {
        try {
          await Share.shareXFiles(
            [XFile(fallbackFile.path, mimeType: mimeType, name: fileName)],
            text: 'Exported packaging label artwork: $fileName',
            subject: fileName,
          );
        } catch (_) {}
      }
      return fallbackFile.path;
    } catch (e2) {
      debugPrint('Fallback write error: $e2');
      return null;
    }
  }
}

Future<String?> triggerBytesDownload({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
  bool shareOnMobile = true,
}) async {
  try {
    final dirPath = await _getDownloadDirectoryPath();
    final file = File('$dirPath/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    debugPrint('Bytes saved directly to: ${file.path}');

    if (shareOnMobile && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await Share.shareXFiles(
          [XFile(file.path, mimeType: mimeType, name: fileName)],
          text: 'Exported packaging label artwork: $fileName',
          subject: fileName,
        );
      } catch (e) {
        debugPrint('Auto-share error: $e');
      }
    }

    return file.path;
  } catch (e) {
    debugPrint('Error writing bytes to device, falling back to temp: $e');
    try {
      final fallbackFile = File('${Directory.systemTemp.path}/$fileName');
      await fallbackFile.writeAsBytes(bytes, flush: true);
      if (shareOnMobile && (Platform.isAndroid || Platform.isIOS)) {
        try {
          await Share.shareXFiles(
            [XFile(fallbackFile.path, mimeType: mimeType, name: fileName)],
            text: 'Exported packaging label artwork: $fileName',
            subject: fileName,
          );
        } catch (_) {}
      }
      return fallbackFile.path;
    } catch (e2) {
      debugPrint('Fallback bytes write error: $e2');
      return null;
    }
  }
}

Future<String?> triggerSvgToPngDownload({
  required String fileName,
  required String svgContent,
  int width = 1200,
  int height = 1800,
  bool shareOnMobile = true,
}) async {
  try {
    final svgFileName = fileName.endsWith('.png') ? fileName.replaceAll('.png', '.svg') : fileName;
    return await triggerDownload(
      fileName: svgFileName,
      content: svgContent,
      mimeType: 'image/svg+xml;charset=utf-8',
      shareOnMobile: shareOnMobile,
    );
  } catch (e) {
    debugPrint('Error writing artwork on device: $e');
    return null;
  }
}

Future<void> triggerNativeShare({
  required String title,
  required String text,
  String? url,
  String? filePath,
}) async {
  try {
    if (filePath != null && await File(filePath).exists()) {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: text,
        subject: title,
      );
    } else {
      await Share.share(
        url != null ? '$text\n\n$url' : text,
        subject: title,
      );
    }
  } catch (e) {
    debugPrint('Error opening native share sheet: $e');
  }
}
