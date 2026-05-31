import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStoreService {
  static const String _pendingQueueKey = 'pending_post_queue_v1';
  static const String _getCacheKey = 'get_cache_v1';
  static const String _sessionUserKey = 'session_user_v1';
  static const String _offlineCredentialKey = 'offline_credentials_v2';
  static const String _inAppNotificationsKey = 'in_app_notifications_v1';
  static const Duration _getCacheTtl = Duration(minutes: 15);

  static SharedPreferences? _prefs;

  static final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    pendingCount.value = getPendingPosts().length;
  }

  static Future<void> refreshPendingCount() async {
    await init();
    pendingCount.value = getPendingPosts().length;
  }

  static Future<void> cacheGetResponse(
      String cacheKey, Map<String, dynamic> value) async {
    await init();
    final bucket = _getCacheMap();
    bucket[cacheKey] = {
      'cached_at_ms': DateTime.now().millisecondsSinceEpoch,
      'value': value,
    };
    await _prefs!.setString(_getCacheKey, jsonEncode(bucket));
  }

  static Map<String, dynamic>? readCachedGetResponse(String cacheKey) {
    final bucket = _getCacheMap();
    final raw = bucket[cacheKey];
    if (raw is Map<String, dynamic>)
      return _parseCachedGet(raw, bucket, cacheKey);
    if (raw is Map)
      return _parseCachedGet(Map<String, dynamic>.from(raw), bucket, cacheKey);
    return null;
  }

  static List<Map<String, dynamic>> getPendingPosts() {
    final raw = _prefs?.getString(_pendingQueueKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> appendPendingPost(Map<String, dynamic> item) async {
    await init();
    final list = getPendingPosts();
    list.add(item);
    await _prefs!.setString(_pendingQueueKey, jsonEncode(list));
    await refreshPendingCount();
  }

  static Future<void> replacePendingPosts(
      List<Map<String, dynamic>> list) async {
    await init();
    await _prefs!.setString(_pendingQueueKey, jsonEncode(list));
    await refreshPendingCount();
  }

  static Future<void> saveSessionUser(Map<String, dynamic> user) async {
    await init();
    await _prefs!.setString(_sessionUserKey, jsonEncode(user));
  }

  static Map<String, dynamic>? readSessionUser() {
    final raw = _prefs?.getString(_sessionUserKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }

  static Future<void> saveOfflineCredential({
    required String email,
    required String pinHash,
    required Map<String, dynamic> user,
  }) async {
    await init();
    final payload = {
      'email': email,
      'pin_hash': pinHash,
      'user': user,
      'saved_at': DateTime.now().toIso8601String(),
    };
    await _prefs!.setString(_offlineCredentialKey, jsonEncode(payload));
  }

  static Map<String, dynamic>? readOfflineCredential() {
    final raw = _prefs?.getString(_offlineCredentialKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }

  static Future<void> clearSessionAndCredential() async {
    await init();
    await _prefs!.remove(_sessionUserKey);
    await _prefs!.remove(_offlineCredentialKey);
  }

  static List<Map<String, dynamic>> readInAppNotifications() {
    final raw = _prefs?.getString(_inAppNotificationsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> appendInAppNotification(
      Map<String, dynamic> event) async {
    await init();
    final list = readInAppNotifications();
    list.insert(0, event);
    if (list.length > 200) {
      list.removeRange(200, list.length);
    }
    await _prefs!.setString(_inAppNotificationsKey, jsonEncode(list));
  }

  static Map<String, dynamic> _getCacheMap() {
    final raw = _prefs?.getString(_getCacheKey);
    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {};
  }

  static Map<String, dynamic>? _parseCachedGet(
    Map<String, dynamic> raw,
    Map<String, dynamic> bucket,
    String cacheKey,
  ) {
    if (raw.containsKey('cached_at_ms') && raw['value'] is Map) {
      final savedAtMs =
          int.tryParse((raw['cached_at_ms'] ?? '').toString()) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final expired =
          savedAtMs <= 0 || (nowMs - savedAtMs) > _getCacheTtl.inMilliseconds;
      if (expired) {
        bucket.remove(cacheKey);
        _prefs?.setString(_getCacheKey, jsonEncode(bucket));
        return null;
      }
      return Map<String, dynamic>.from(raw['value'] as Map);
    }

    // Backward compatibility for old cache structure.
    return raw;
  }
}
