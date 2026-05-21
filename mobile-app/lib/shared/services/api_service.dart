import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_config.dart';
import 'local_store_service.dart';

class ApiService {
  final http.Client _client;
  ApiService({http.Client? client}) : _client = client ?? http.Client();
  static const Set<String> _queueableActions = {
    'createTransaction',
    'upsertBeneficiary',
    'upsertStaff',
    'recordSalaryPayment',
    'saveScholarshipPayment',
  };

  Future<Map<String, dynamic>> get(String action, {Map<String, String>? query}) async {
    final params = {'action': action, ...?query};
    final uri = Uri.parse(AppConfig.apiBaseUrl).replace(queryParameters: params);
    final cacheKey = _cacheKey(action, query);

    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 30));
      final parsed = _parse(res);
      if (parsed['ok'] == true) {
        await LocalStoreService.cacheGetResponse(cacheKey, parsed);
      }
      return parsed;
    } catch (_) {
      final cached = LocalStoreService.readCachedGetResponse(cacheKey);
      if (cached != null) {
        return {
          ...cached,
          'offline': true,
          'cached': true,
          'message': 'Offline mode: showing cached data',
        };
      }
      return {
        'ok': false,
        'offline': true,
        'message': 'No internet and no cached data available',
      };
    }
  }

  Future<Map<String, dynamic>> post(
    String action,
    Map<String, dynamic> payload, {
    bool allowQueue = true,
  }) async {
    final uri = Uri.parse(AppConfig.apiBaseUrl);
    final body = {'action': action, ...payload};
    try {
      final res = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return _parse(res);
    } catch (_) {
      if (allowQueue && _queueableActions.contains(action)) {
        await LocalStoreService.appendPendingPost({
          'action': action,
          'payload': payload,
          'queued_at': DateTime.now().toIso8601String(),
        });
        return {
          'ok': true,
          'queued': true,
          'offline': true,
          'message': 'Saved offline. Will sync when internet is available.',
        };
      }
      return {
        'ok': false,
        'offline': true,
        'message': 'Request failed in offline mode',
      };
    }
  }

  Map<String, dynamic> _parse(http.Response res) {
    if (res.body.isEmpty) {
      return {'ok': false, 'message': 'Empty server response'};
    }

    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'ok': false, 'message': 'Invalid response format'};
    } catch (_) {
      return {'ok': false, 'message': 'Invalid JSON response from server'};
    }
  }

  String _cacheKey(String action, Map<String, String>? query) {
    if (query == null || query.isEmpty) return action;
    final entries = query.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final queryPart = entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$action?$queryPart';
  }
}
