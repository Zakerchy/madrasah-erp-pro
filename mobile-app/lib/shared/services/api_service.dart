import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/app_config.dart';
import 'local_store_service.dart';
import 'session_service.dart';

class ApiService {
  static const Set<String> _queueableActions = {
    'createTransaction',
    'upsertBeneficiary',
    'upsertStaff',
    'recordSalaryPayment',
    'saveScholarshipPayment',
    'upsertStudent',
    'upsertStudentGuardian',
    'upsertClass',
    'upsertSection',
    'upsertSubject',
    'saveAttendance',
    'upsertExamTerm',
    'saveExamMark',
    'upsertFeePlan',
    'recordFeePayment',
    'upsertFeeWaiver',
    'upsertBudget',
    'upsertApprovalRule',
    'createApprovalRequest',
    'decideApprovalRequest',
    'upsertUser',
    'setUserApprovalStatus',
  };

  static String hashPin(String pin) {
    final bytes = utf8.encode(pin.trim());
    return sha256.convert(bytes).toString();
  }

  bool get _isConfigured => !AppConfig.isUsingPlaceholderUrl;

  // Apps Script web apps return a 302 redirect on POST.
  // The redirect URL (script.googleusercontent.com) serves the JSON response via GET.
  Future<Map<String, dynamic>> _postToAppsScript(
    Map<String, dynamic> payload,
  ) async {
    final client = http.Client();
    try {
      // Step 1: POST without following redirects
      final req = http.Request('POST', Uri.parse(AppConfig.appsScriptUrl))
        // For Flutter Web + Google Apps Script:
        // Use text/plain to keep request CORS-simple (avoids OPTIONS preflight).
        ..headers['Content-Type'] =
            kIsWeb ? 'text/plain;charset=utf-8' : 'application/json'
        ..body = jsonEncode(payload);
      final streamed =
          await client.send(req).timeout(const Duration(seconds: 25));

      String? location;
      if (streamed.statusCode == 302 || streamed.statusCode == 301) {
        location = streamed.headers['location'];
      }

      if (location != null) {
        // Step 2: GET the redirect URL to retrieve the response
        final res = await client
            .get(Uri.parse(location))
            .timeout(const Duration(seconds: 20));
        if (res.statusCode == 200) {
          return jsonDecode(res.body) as Map<String, dynamic>;
        }
        throw Exception('Redirect GET HTTP ${res.statusCode}');
      }

      // No redirect — read body directly
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) {
        return jsonDecode(body) as Map<String, dynamic>;
      }
      throw Exception('HTTP ${streamed.statusCode}');
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> _send(
    String action,
    Map<String, dynamic> body, {
    bool allowQueue = true,
  }) async {
    final isReadOnly = !_queueableActions.contains(action);
    final cacheKey = '${action}_${jsonEncode(_stableSort(body))}';

    if (!_isConfigured) {
      final cached = LocalStoreService.readCachedGetResponse(cacheKey);
      if (cached != null) return {...cached, 'cached': true};
      return {
        'ok': false,
        'message':
            'Apps Script URL সেট করা হয়নি। APPS_SCRIPT_URL / API_BASE_URL / APPS_SCRIPT_DEPLOYMENT_ID dart-define দিন।',
      };
    }

    try {
      final decoded = await _postToAppsScript({'action': action, ...body});
      if (decoded['ok'] == true && isReadOnly) {
        await LocalStoreService.cacheGetResponse(cacheKey, decoded);
      }
      return decoded;
    } catch (e) {
      if (isReadOnly) {
        final cached = LocalStoreService.readCachedGetResponse(cacheKey);
        if (cached != null) {
          return {...cached, 'offline': true, 'cached': true};
        }
        return {
          'ok': false,
          'offline': true,
          'message': 'ইন্টারনেট নেই এবং cached তথ্য নেই'
        };
      }
      if (allowQueue && _queueableActions.contains(action)) {
        await LocalStoreService.appendPendingPost({
          'action': action,
          'payload': body,
          'queued_at': DateTime.now().toIso8601String(),
        });
        return {
          'ok': true,
          'queued': true,
          'offline': true,
          'message': 'অফলাইনে সংরক্ষিত। সংযোগে এলে পাঠানো হবে।',
        };
      }
      return {'ok': false, 'offline': true, 'message': 'অনুরোধ ব্যর্থ: $e'};
    }
  }

  Map<String, dynamic> _stableSort(Map<String, dynamic> map) {
    return Map.fromEntries(
        map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  Future<Map<String, dynamic>> get(String action,
      {Map<String, dynamic>? query}) {
    return _send(action, {
      'user_role': SessionService.role,
      'user_id': SessionService.userId,
      ...?query,
    });
  }

  Future<Map<String, dynamic>> post(
    String action,
    Map<String, dynamic> payload, {
    bool allowQueue = true,
  }) {
    return _send(action, payload, allowQueue: allowQueue);
  }
}
