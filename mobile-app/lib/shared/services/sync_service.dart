import 'api_service.dart';
import 'local_store_service.dart';
import 'session_service.dart';

class SyncService {
  static Future<Map<String, dynamic>> syncPending() async {
    await LocalStoreService.init();
    final queue = LocalStoreService.getPendingPosts();

    if (queue.isEmpty) {
      return {'ok': true, 'synced': 0, 'remaining': 0};
    }

    final api = ApiService();
    final remaining = <Map<String, dynamic>>[];
    final syncedActions = <String>{};
    var synced = 0;

    for (final item in queue) {
      final action = (item['action'] ?? '').toString();
      final payload = Map<String, dynamic>.from(item['payload'] as Map? ?? {});
      final res = await api.post(action, payload, allowQueue: false);
      if (res['ok'] == true) {
        synced++;
        syncedActions.add(action);
      } else {
        remaining.add(item);
        final failedAt = DateTime.now().toIso8601String();
        await LocalStoreService.appendInAppNotification({
          'id': 'local_sync_fail_$failedAt',
          'category': 'failed_sync',
          'title': 'Sync failed',
          'message':
              'Queued action "$action" failed and will retry automatically.',
          'created_at': failedAt,
          'source': 'local_sync_worker',
        });

        try {
          await api.post(
              'createNotificationEvent',
              {
                'user_role': SessionService.role,
                'user_id': SessionService.userId,
                'payload': {
                  'category': 'failed_sync',
                  'title': 'Sync failed',
                  'message':
                      'Queued action "$action" failed and will retry automatically.',
                },
              },
              allowQueue: false);
        } catch (_) {
          // No-op. In-app local event is already captured above.
        }
      }
    }

    await LocalStoreService.replacePendingPosts(remaining);
    if (syncedActions.isNotEmpty) {
      await LocalStoreService.invalidateGetCache();
    }
    return {
      'ok': true,
      'synced': synced,
      'remaining': remaining.length,
    };
  }
}
