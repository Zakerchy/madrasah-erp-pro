import 'package:flutter/foundation.dart';

import '../models/session_user.dart';
import 'local_store_service.dart';

class SessionService {
  static final ValueNotifier<SessionUser?> currentUser = ValueNotifier<SessionUser?>(null);

  static SessionUser? get user => currentUser.value;
  static String get role => user?.role ?? 'VIEWER';
  static String get userId => user?.id ?? 'unknown';
  static String get userName => user?.name ?? 'Unknown';

  static Future<void> bootstrap() async {
    await LocalStoreService.init();
    final cachedUser = LocalStoreService.readSessionUser();
    if (cachedUser != null) {
      currentUser.value = SessionUser.fromMap(cachedUser);
    }
  }

  static void setUser(SessionUser next) {
    currentUser.value = next;
    LocalStoreService.saveSessionUser(next.toMap());
  }

  static Future<void> saveOfflineCredential({
    required String email,
    required String pinHash,
    required SessionUser user,
  }) async {
    await LocalStoreService.saveOfflineCredential(
      email: email,
      pinHash: pinHash,
      user: user.toMap(),
    );
  }

  static bool loginFromOfflineCredential({
    required String email,
    required String pinHash,
  }) {
    final creds = LocalStoreService.readOfflineCredential();
    if (creds == null) return false;

    final cEmail = (creds['email'] ?? '').toString().trim().toLowerCase();
    final cPinHash = (creds['pin_hash'] ?? '').toString().trim();
    final uMap = Map<String, dynamic>.from(creds['user'] as Map? ?? {});

    if (cEmail != email.trim().toLowerCase() || uMap.isEmpty) return false;
    // Allow offline login if PIN matches or no PIN was set
    if (cPinHash.isNotEmpty && pinHash.isNotEmpty && cPinHash != pinHash) return false;

    setUser(SessionUser.fromMap(uMap));
    return true;
  }

  static void clear() {
    currentUser.value = null;
    LocalStoreService.clearSessionAndCredential();
  }
}
