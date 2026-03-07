import 'dart:typed_data';

import 'file_transfer_stub.dart' if (dart.library.html) 'file_transfer_web.dart'
    as impl;

Future<String?> pickTextFile({required String accept}) {
  return impl.pickTextFile(accept: accept);
}

void downloadText(
  String text, {
  required String fileName,
  String mimeType = 'text/plain',
}) {
  impl.downloadText(text, fileName: fileName, mimeType: mimeType);
}

void downloadBytes(
  Uint8List bytes, {
  required String fileName,
  String mimeType = 'application/octet-stream',
}) {
  impl.downloadBytes(bytes, fileName: fileName, mimeType: mimeType);
}

