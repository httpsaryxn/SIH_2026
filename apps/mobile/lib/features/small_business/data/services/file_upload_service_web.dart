// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'file_upload_service.dart';

Future<UploadedFilePayload?> pickFile({required String acceptedTypes}) async {
  final completer = Completer<UploadedFilePayload?>();

  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = acceptedTypes;
  uploadInput.click();

  uploadInput.onChange.listen((event) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files.first;
      final reader = html.FileReader();

      reader.onLoadEnd.listen((_) {
        final dataUrl = reader.result as String?;
        final extension = file.name.contains('.')
            ? '.${file.name.split('.').last}'
            : '';

        completer.complete(
          UploadedFilePayload(
            name: file.name,
            sizeInBytes: file.size,
            dataUrl: dataUrl,
            extension: extension,
          ),
        );
      });

      reader.onError.listen((error) {
        completer.complete(null);
      });

      reader.readAsDataUrl(file);
    } else {
      completer.complete(null);
    }
  });

  return completer.future;
}
