import 'file_save_service_stub.dart'
    if (dart.library.html) 'file_save_service_web.dart';

/// Triggers a browser "Save as" download. On platforms without a browser
/// (Android/iOS native), [download] returns false — callers fall back to
/// the OS share sheet (which lets the user save to Files/Gallery) instead.
abstract class FileSaveService {
  Future<bool> download(List<int> bytes, String filename, {String mimeType});
}

final FileSaveService fileSaveService = createFileSaveService();
