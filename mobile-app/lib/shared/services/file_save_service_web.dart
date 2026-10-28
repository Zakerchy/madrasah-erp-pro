// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'file_save_service.dart';

FileSaveService createFileSaveService() => _WebFileSaveService();

class _WebFileSaveService implements FileSaveService {
  @override
  Future<bool> download(List<int> bytes, String filename, {String mimeType = 'image/png'}) async {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
    return true;
  }
}
