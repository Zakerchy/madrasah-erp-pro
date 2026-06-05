import 'package:flutter/foundation.dart';

import '../models/session_user.dart';
import 'local_store_service.dart';
import 'role_service.dart';

class SessionService {
  static final ValueNotifier<SessionUser?> currentUser = ValueNotifier<SessionUser?>(null);

  static SessionUser? get user => currentUser.value;
  static bool get isLoggedIn => user != null;
  static String get role => user?.role ?? 'VIEWER';
  static String get userId => user?.id ?? 'unknown';
  static String get userName => user?.name ?? 'Unknown';
  static List<String> get permissions {
    final current = user?.permissions ?? const [];
    if (current.isNotEmpty) return current;
    return RoleService.permissionsForRole(role);
  }

  static Future<void> bootstrap() async {
    await LocalStoreService.init();
    await RoleService.bootstrap();
    final cachedUser = LocalStoreService.readSessionUser();
    if (cachedUser != null) {
      final next = SessionUser.fromMap(cachedUser);
      currentUser.value = next.permissions.isNotEmpty
          ? next
          : SessionUser(
              id: next.id,
              name: next.name,
              role: next.role,
              phone: next.phone,
              email: next.email,
              approvalStatus: next.approvalStatus,
              permissions: RoleService.permissionsForRole(next.role),
            );
      LocalStoreService.saveSessionUser(currentUser.value!.toMap());
    }
  }

  static void setUser(SessionUser next) {
    final permissions = next.permissions.isNotEmpty
        ? next.permissions
        : RoleService.permissionsForRole(next.role);
    currentUser.value = SessionUser(
      id: next.id,
      name: next.name,
      role: next.role,
      phone: next.phone,
      email: next.email,
      approvalStatus: next.approvalStatus,
      permissions: permissions,
    );
    LocalStoreService.saveSessionUser(currentUser.value!.toMap());
  }

  static bool can(String permission) {
    return RoleService.hasPermission(
      permission,
      role: role,
      permissions: permissions,
    );
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
