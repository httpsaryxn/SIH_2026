import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Resolves the most appropriate public Downloads or documents folder
Future<String> _getDownloadDirectoryPath() async {
  if (Platform.isAndroid) {
    try {
      final androidDownloadDir = Directory('/storage/emulated/0/Download');
      if (await androidDownloadDir.exists()) {
        final testFile = File('${androidDownloadDir.path}/.test_probe_${DateTime.now().millisecondsSinceEpoch}');
        await testFile.writeAsString('test', flush: true);
        await testFile.delete();
        return androidDownloadDir.path;
      }
    } catch (_) {}
  }

  try {
    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null && await downloadsDir.exists()) {
      return downloadsDir.path;
    }
  } catch (_) {}

  try {
    final extDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
    if (extDirs != null && extDirs.isNotEmpty) {
      final dir = extDirs.first;
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir.path;
    }
  } catch (_) {}

  try {
    final extDir = await getExternalStorageDirectory();
    if (extDir != null) {
      if (!await extDir.exists()) await extDir.create(recursive: true);
      return extDir.path;
    }
  } catch (_) {}

  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    if (!await appDocDir.exists()) await appDocDir.create(recursive: true);
    return appDocDir.path;
  } catch (_) {}

  return Directory.systemTemp.path;
}

Future<String?> triggerDownload({
  required String fileName,
  required String content,
  required String mimeType,
}) async {
  try {
    final dirPath = await _getDownloadDirectoryPath();
    final file = File('$dirPath/$fileName');
    await file.writeAsString(content, encoding: utf8, flush: true);
    debugPrint('File saved directly to: ${file.path}');
    return file.path;
  } catch (e) {
    debugPrint('Error writing file on device, falling back to temp: $e');
    try {
      final fallbackFile = File('${Directory.systemTemp.path}/$fileName');
      await fallbackFile.writeAsString(content, encoding: utf8, flush: true);
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
}) async {
  try {
    final dirPath = await _getDownloadDirectoryPath();
    final file = File('$dirPath/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    debugPrint('Bytes saved directly to: ${file.path}');
    return file.path;
  } catch (e) {
    debugPrint('Error writing bytes to device, falling back to temp: $e');
    try {
      final fallbackFile = File('${Directory.systemTemp.path}/$fileName');
      await fallbackFile.writeAsBytes(bytes, flush: true);
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
}) async {
  try {
    return await triggerDownload(
      fileName: fileName,
      content: svgContent,
      mimeType: 'image/svg+xml',
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
