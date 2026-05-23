import 'dart:convert';

import 'package:crypto/crypto.dart';
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
    'upsertUser',
    'setUserApprovalStatus',
  };

  static String hashPin(String pin) {
    final bytes = utf8.encode(pin.trim());
    return sha256.convert(bytes).toString();
  }

  bool get _isConfigured => !AppConfig.appsScriptUrl.contains('PLACEHOLDER');

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
        'message': 'Apps Script URL সেট করা হয়নি। Admin-এর কাছ থেকে URL নিন।',
      };
    }

    try {
      final res = await http
          .post(
            Uri.parse(AppConfig.appsScriptUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': action, ...body}),
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['ok'] == true && isReadOnly) {
            await LocalStoreService.cacheGetResponse(cacheKey, decoded);
          }
          return decoded;
        }
        return {'ok': false, 'message': 'Server থেকে অপ্রত্যাশিত response'};
      }
      throw Exception('HTTP ${res.statusCode}');
    } catch (e) {
      if (isReadOnly) {
        final cached = LocalStoreService.readCachedGetResponse(cacheKey);
        if (cached != null) {
          return {...cached, 'offline': true, 'cached': true};
        }
        return {'ok': false, 'offline': true, 'message': 'ইন্টারনেট নেই এবং cached তথ্য নেই'};
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
