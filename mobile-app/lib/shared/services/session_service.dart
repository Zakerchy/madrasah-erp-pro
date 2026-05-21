import 'package:flutter/foundation.dart';

import '../models/session_user.dart';

class SessionService {
  static final ValueNotifier<SessionUser?> currentUser = ValueNotifier<SessionUser?>(null);

  static SessionUser? get user => currentUser.value;
  static String get role => user?.role ?? 'VIEWER';
  static String get userId => user?.id ?? 'unknown';
  static String get userName => user?.name ?? 'Unknown';

  static void setUser(SessionUser next) {
    currentUser.value = next;
  }

  static void clear() {
    currentUser.value = null;
  }
}
