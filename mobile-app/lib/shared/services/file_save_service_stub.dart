import 'file_save_service.dart';

FileSaveService createFileSaveService() => _StubFileSaveService();

class _StubFileSaveService implements FileSaveService {
  @override
  Future<bool> download(List<int> bytes, String filename, {String mimeType = 'image/png'}) async {
    return false;
  }
}
