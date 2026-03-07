import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<String?> pickTextFile({required String accept}) {
  final completer = Completer<String?>();

  final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()
    ..accept = accept;

  uploadInput.onChange.listen((_) {
    final files = uploadInput.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      return;
    }

    final file = files.first;
    final reader = html.FileReader();
    reader.readAsText(file);

    reader.onLoadEnd.listen((_) {
      if (!completer.isCompleted) {
        completer.complete(reader.result as String?);
      }
    });
    reader.onError.listen((_) {
      if (!completer.isCompleted) {
        completer.completeError(reader.error ?? '读取文件失败');
      }
    });
  });

  uploadInput.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.completeError('选择文件失败');
    }
  });

  uploadInput.click();
  return completer.future;
}

void downloadText(
  String text, {
  required String fileName,
  String mimeType = 'text/plain',
}) {
  final blob = html.Blob([text], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void downloadBytes(
  Uint8List bytes, {
  required String fileName,
  String mimeType = 'application/octet-stream',
}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

