import 'dart:async';

void triggerDownload({
  required String fileName,
  required String content,
  required String mimeType,
}) {}

void triggerBytesDownload({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) {}

Future<void> triggerSvgToPngDownload({
  required String fileName,
  required String svgContent,
  int width = 1200,
  int height = 1800,
}) async {}

void triggerNativeShare({
  required String title,
  required String text,
  String? url,
}) {}
