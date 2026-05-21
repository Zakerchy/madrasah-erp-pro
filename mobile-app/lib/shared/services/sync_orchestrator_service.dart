import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'local_store_service.dart';
import 'sync_service.dart';

class SyncOrchestratorService {
  static Timer? _timer;
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  static bool _started = false;
  static bool _syncing = false;

  static Future<void> start() async {
    if (_started) return;
    _started = true;

    await LocalStoreService.init();
    await _trySync();

    _timer = Timer.periodic(const Duration(minutes: 3), (_) async {
      await _trySync();
    });

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) async {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        await _trySync();
      }
    });
  }

  static Future<void> _trySync() async {
    if (_syncing) return;
    _syncing = true;
    try {
      await SyncService.syncPending();
    } catch (_) {
      // Silent by design: sync worker retries on next periodic/reconnect trigger.
    } finally {
      _syncing = false;
    }
  }

  static Future<void> stop() async {
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    _timer?.cancel();
    _timer = null;
    _started = false;
  }
}
