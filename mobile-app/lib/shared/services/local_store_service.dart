import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStoreService {
  static const String _pendingQueueKey = 'pending_post_queue_v1';
  static const String _getCacheKey = 'get_cache_v1';
  static const String _sessionUserKey = 'session_user_v1';
  static const String _offlineCredentialKey = 'offline_credentials_v2';
  static const String _inAppNotificationsKey = 'in_app_notifications_v1';
  static const Duration _getCacheTtl = Duration(hours: 6);
  static const Duration _staleGetCacheTtl = Duration(days: 14);
  static const int _maxGetCacheEntries = 80;

  static SharedPreferences? _prefs;

  static final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _pruneCaches();
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
    _trimCacheBucket(bucket);
    await _prefs!.setString(_getCacheKey, jsonEncode(bucket));
  }

  static Map<String, dynamic>? readCachedGetResponse(
    String cacheKey, {
    Duration? maxAge,
    bool allowExpired = false,
  }) {
    final bucket = _getCacheMap();
    final raw = bucket[cacheKey];
    if (raw is Map<String, dynamic>) {
      return _parseCachedGet(
        raw,
        bucket,
        cacheKey,
        maxAge: maxAge,
        allowExpired: allowExpired,
      );
    }
    if (raw is Map) {
      return _parseCachedGet(
        Map<String, dynamic>.from(raw),
        bucket,
        cacheKey,
        maxAge: maxAge,
        allowExpired: allowExpired,
      );
    }
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
    final next = Map<String, dynamic>.from(item);
    final fingerprint = _stableJson({
      'action': next['action'],
      'payload': _stableSortValue(next['payload']),
    });
    final duplicate = list.any((existing) {
      final existingFingerprint = _stableJson({
        'action': existing['action'],
        'payload': _stableSortValue(existing['payload']),
      });
      return existingFingerprint == fingerprint;
    });
    if (duplicate) {
      await refreshPendingCount();
      return;
    }
    list.add(next);
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

  static Future<void> invalidateGetCache(
      {Iterable<String>? actionPrefixes}) async {
    await init();
    if (actionPrefixes == null || actionPrefixes.isEmpty) {
      await _prefs!.remove(_getCacheKey);
      return;
    }
    final bucket = _getCacheMap();
    bucket.removeWhere((key, _) =>
        actionPrefixes.any((prefix) => key.startsWith('${prefix}_')));
    await _prefs!.setString(_getCacheKey, jsonEncode(bucket));
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
    {Duration? maxAge,
    bool allowExpired = false,}
  ) {
    if (raw.containsKey('cached_at_ms') && raw['value'] is Map) {
      final savedAtMs =
          int.tryParse((raw['cached_at_ms'] ?? '').toString()) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final ageMs = nowMs - savedAtMs;
      final hardExpired =
          savedAtMs <= 0 || ageMs > _staleGetCacheTtl.inMilliseconds;
      if (hardExpired) {
        bucket.remove(cacheKey);
        _prefs?.setString(_getCacheKey, jsonEncode(bucket));
        return null;
      }
      final ttl = maxAge ?? _getCacheTtl;
      final softExpired = savedAtMs <= 0 || ageMs > ttl.inMilliseconds;
      if (softExpired && !allowExpired) return null;
      return Map<String, dynamic>.from(raw['value'] as Map);
    }

    // Backward compatibility for old cache structure.
    return raw;
  }

  static Future<void> _pruneCaches() async {
    final bucket = _getCacheMap();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    bucket.removeWhere((_, value) {
      if (value is! Map) return false;
      final savedAtMs =
          int.tryParse((value['cached_at_ms'] ?? '').toString()) ?? 0;
      if (savedAtMs <= 0) return false;
      return (nowMs - savedAtMs) > _staleGetCacheTtl.inMilliseconds;
    });
    _trimCacheBucket(bucket);
    await _prefs?.setString(_getCacheKey, jsonEncode(bucket));
  }

  static void _trimCacheBucket(Map<String, dynamic> bucket) {
    if (bucket.length <= _maxGetCacheEntries) return;
    final entries = bucket.entries.toList()
      ..sort((a, b) {
        final aMs = _cacheEntryTimestamp(a.value);
        final bMs = _cacheEntryTimestamp(b.value);
        return aMs.compareTo(bMs);
      });
    final trimCount = bucket.length - _maxGetCacheEntries;
    for (var i = 0; i < trimCount; i++) {
      bucket.remove(entries[i].key);
    }
  }

  static int _cacheEntryTimestamp(dynamic value) {
    if (value is! Map) return 0;
    return int.tryParse((value['cached_at_ms'] ?? '').toString()) ?? 0;
  }

  static dynamic _stableSortValue(dynamic value) {
    if (value is Map) {
      final entries = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return {
        for (final entry in entries) entry.key.toString(): _stableSortValue(entry.value),
      };
    }
    if (value is List) {
      return value.map(_stableSortValue).toList();
    }
    return value;
  }

  static String _stableJson(Map<String, dynamic> value) =>
      jsonEncode(_stableSortValue(value));
}
