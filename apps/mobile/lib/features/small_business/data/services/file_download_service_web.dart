// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

void triggerDownload({
  required String fileName,
  required String content,
  required String mimeType,
}) {
  final href = content.startsWith('data:')
      ? content
      : 'data:$mimeType;charset=utf-8,${Uri.encodeComponent(content)}';

  final anchor = html.AnchorElement(href: href)
    ..setAttribute('download', fileName)
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
}

void triggerBytesDownload({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}

/// Renders SVG directly to a canvas and exports genuine binary PNG
Future<void> triggerSvgToPngDownload({
  required String fileName,
  required String svgContent,
  int width = 1200,
  int height = 1800,
}) async {
  final svgBlob = html.Blob([svgContent], 'image/svg+xml;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(svgBlob);
  final img = html.ImageElement();

  final completer = Completer<void>();

  img.onLoad.listen((_) {
    final canvas = html.CanvasElement(width: width, height: height);
    final ctx = canvas.context2D;
    ctx.fillStyle = '#FFFFFF';
    ctx.fillRect(0, 0, width, height);
    ctx.drawImageScaled(img, 0, 0, width, height);
    html.Url.revokeObjectUrl(url);

    final pngDataUrl = canvas.toDataUrl('image/png');
    final anchor = html.AnchorElement(href: pngDataUrl)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    completer.complete();
  });

  img.onError.listen((e) {
    html.Url.revokeObjectUrl(url);
    // Fallback to direct SVG download
    triggerDownload(
      fileName: fileName.replaceAll('.png', '.svg'),
      content: svgContent,
      mimeType: 'image/svg+xml',
    );
    completer.complete();
  });

  img.src = url;
  return completer.future;
}

void triggerNativeShare({
  required String title,
  required String text,
  String? url,
}) {
  try {
    html.window.navigator.share({
      'title': title,
      'text': text,
      'url': url ?? html.window.location.href,
    });
  } catch (_) {}
}
