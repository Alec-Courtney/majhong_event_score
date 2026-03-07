import 'dart:typed_data';

Future<String?> pickTextFile({required String accept}) {
  throw UnsupportedError('当前平台不支持选择文件（仅 Web 支持）。');
}

void downloadText(
  String text, {
  required String fileName,
  String mimeType = 'text/plain',
}) {
  throw UnsupportedError('当前平台不支持下载文件（仅 Web 支持）。');
}

void downloadBytes(
  Uint8List bytes, {
  required String fileName,
  String mimeType = 'application/octet-stream',
}) {
  throw UnsupportedError('当前平台不支持下载文件（仅 Web 支持）。');
}

