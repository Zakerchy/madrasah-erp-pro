import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStoreService {
  static const String _pendingQueueKey = 'pending_post_queue_v1';
  static const String _getCacheKey = 'get_cache_v1';
  static const String _sessionUserKey = 'session_user_v1';
  static const String _offlineCredentialKey = 'offline_credentials_v2';

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

  static Future<void> cacheGetResponse(String cacheKey, Map<String, dynamic> value) async {
    await init();
    final bucket = _getCacheMap();
    bucket[cacheKey] = value;
    await _prefs!.setString(_getCacheKey, jsonEncode(bucket));
  }

  static Map<String, dynamic>? readCachedGetResponse(String cacheKey) {
    final bucket = _getCacheMap();
    final raw = bucket[cacheKey];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static List<Map<String, dynamic>> getPendingPosts() {
    final raw = _prefs?.getString(_pendingQueueKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> appendPendingPost(Map<String, dynamic> item) async {
    await init();
    final list = getPendingPosts();
    list.add(item);
    await _prefs!.setString(_pendingQueueKey, jsonEncode(list));
    await refreshPendingCount();
  }

  static Future<void> replacePendingPosts(List<Map<String, dynamic>> list) async {
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
    required String googleId,
    required Map<String, dynamic> user,
  }) async {
    await init();
    final payload = {
      'email': email,
      'google_id': googleId,
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

  static Map<String, dynamic> _getCacheMap() {
    final raw = _prefs?.getString(_getCacheKey);
    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {};
  }
}
