import 'dart:typed_data';

class PickedDocumentFile {
  const PickedDocumentFile({
    required this.name,
    required this.bytes,
    required this.sizeBytes,
    this.extension,
  });

  final String name;
  final Uint8List bytes;
  final int sizeBytes;
  final String? extension;

  String get mimeType {
    switch ((extension ?? '').toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
