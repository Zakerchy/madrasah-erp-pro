import 'api_service.dart';
import 'local_store_service.dart';

class SyncService {
  static Future<Map<String, dynamic>> syncPending() async {
    await LocalStoreService.init();
    final queue = LocalStoreService.getPendingPosts();

    if (queue.isEmpty) {
      return {'ok': true, 'synced': 0, 'remaining': 0};
    }

    final api = ApiService();
    final remaining = <Map<String, dynamic>>[];
    var synced = 0;

    for (final item in queue) {
      final action = (item['action'] ?? '').toString();
      final payload = Map<String, dynamic>.from(item['payload'] as Map? ?? {});
      final res = await api.post(action, payload, allowQueue: false);
      if (res['ok'] == true) {
        synced++;
      } else {
        remaining.add(item);
      }
    }

    await LocalStoreService.replacePendingPosts(remaining);
    return {
      'ok': true,
      'synced': synced,
      'remaining': remaining.length,
    };
  }
}
