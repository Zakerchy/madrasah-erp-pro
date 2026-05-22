import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_config.dart';
import 'local_store_service.dart';
import 'session_service.dart';

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
    final authQuery = _authQuery();
    final scopedQuery = {...authQuery, ...?query};
    final params = {'action': action, ...scopedQuery};
    final uri = Uri.parse(AppConfig.apiBaseUrl).replace(queryParameters: params);
    final cacheKey = _cacheKey(action, scopedQuery);

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

      final fallback = _offlineFallback(action, scopedQuery);
      if (fallback != null) {
        return {
          ...fallback,
          'offline': true,
          'cached': false,
          'message': 'Offline mode: showing local fallback data',
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

  Map<String, String> _authQuery() {
    final role = SessionService.role;
    final userId = SessionService.userId;
    return {
      'user_role': role,
      'user_id': userId,
    };
  }

  String _cacheKey(String action, Map<String, String>? query) {
    if (query == null || query.isEmpty) return action;
    final entries = query.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final queryPart = entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$action?$queryPart';
  }

  Map<String, dynamic>? _offlineFallback(String action, Map<String, String> query) {
    if (action == 'dashboardSummary') {
      return {
        'ok': true,
        'data': _summaryFromLocalQueue(query),
      };
    }

    if (action == 'listTransactions') {
      return {
        'ok': true,
        'data': _queuedTransactions(query),
      };
    }

    if (action == 'monthlyReport') {
      final monthKey = (query['monthKey'] ?? '').trim();
      final txns = _queuedTransactions(query)
          .where((r) => monthKey.isEmpty || String(r['txn_date'] ?? '').startsWith(monthKey))
          .toList();
      var totalIn = 0.0;
      var totalOut = 0.0;
      for (final t in txns) {
        final amt = _num(t['amount']);
        if (String(t['direction']) == 'IN') {
          totalIn += amt;
        } else {
          totalOut += amt;
        }
      }
      return {
        'ok': true,
        'data': {
          'monthKey': monthKey,
          'totalIn': totalIn,
          'totalOut': totalOut,
          'balance': totalIn - totalOut,
          'rows': txns,
        },
      };
    }

    if (action == 'listBeneficiaries') {
      final list = _queuedActionPayloads('upsertBeneficiary')
          .map((p) => Map<String, dynamic>.from(p['payload'] as Map? ?? {}))
          .toList();
      return {'ok': true, 'data': list};
    }

    if (action == 'listStaff') {
      final list = _queuedActionPayloads('upsertStaff')
          .map((p) => Map<String, dynamic>.from(p['payload'] as Map? ?? {}))
          .toList();
      return {'ok': true, 'data': list};
    }

    if (action == 'listSalaryPayments') {
      final list = _queuedActionPayloads('recordSalaryPayment')
          .map((p) => Map<String, dynamic>.from(p['payload'] as Map? ?? {}))
          .toList();
      return {'ok': true, 'data': list};
    }

    if (action == 'listScholarshipByMonth') {
      final monthKey = (query['monthKey'] ?? '').trim();
      final list = _queuedActionPayloads('saveScholarshipPayment')
          .map((p) => Map<String, dynamic>.from(p['payload'] as Map? ?? {}))
          .where((r) => monthKey.isEmpty || String(r['month_key'] ?? '') == monthKey)
          .toList();
      return {'ok': true, 'data': list};
    }

    return null;
  }

  List<Map<String, dynamic>> _queuedActionPayloads(String action) {
    final queue = LocalStoreService.getPendingPosts();
    return queue
        .where((item) => String(item['action'] ?? '') == action)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> _queuedTransactions(Map<String, String> query) {
    final role = (query['user_role'] ?? '').trim();
    final userId = (query['user_id'] ?? '').trim();
    final direction = (query['direction'] ?? '').trim();
    final fundType = (query['fundType'] ?? '').trim();
    final from = (query['from'] ?? '').trim();
    final to = (query['to'] ?? '').trim();

    final queue = _queuedActionPayloads('createTransaction');
    final rows = <Map<String, dynamic>>[];

    for (final item in queue) {
      final envelope = Map<String, dynamic>.from(item['payload'] as Map? ?? {});
      final payload = Map<String, dynamic>.from(envelope['payload'] as Map? ?? {});
      final row = {
        'id': payload['id'] ?? 'offline_${item['queued_at'] ?? DateTime.now().toIso8601String()}',
        'txn_date': payload['txn_date'] ?? '',
        'direction': payload['direction'] ?? '',
        'fund_type': payload['fund_type'] ?? '',
        'amount': _num(payload['amount']),
        'source_or_vendor': payload['source_or_vendor'] ?? '',
        'category': payload['category'] ?? '',
        'notes': payload['notes'] ?? '',
        'status': payload['status'] ?? 'ACTIVE',
        'created_by': payload['created_by'] ?? '',
        'queued_offline': true,
      };
      rows.add(row);
    }

    final scoped = rows.where((r) {
      if (role == 'FIELD_USER' && String(r['created_by'] ?? '') != userId) return false;
      if (role == 'VIEWER') return false;
      if (direction.isNotEmpty && String(r['direction'] ?? '') != direction) return false;
      if (fundType.isNotEmpty && String(r['fund_type'] ?? '') != fundType) return false;
      final d = String(r['txn_date'] ?? '');
      if (from.isNotEmpty && d.compareTo(from) < 0) return false;
      if (to.isNotEmpty && d.compareTo(to) > 0) return false;
      return true;
    }).toList();

    scoped.sort((a, b) => String(b['txn_date'] ?? '').compareTo(String(a['txn_date'] ?? '')));
    return scoped;
  }

  Map<String, dynamic> _summaryFromLocalQueue(Map<String, String> query) {
    final txns = _queuedTransactions(query);
    final byFund = <String, Map<String, double>>{};
    var totalIn = 0.0;
    var totalOut = 0.0;

    for (final t in txns) {
      final fund = String(t['fund_type'] ?? 'UNKNOWN');
      final amt = _num(t['amount']);
      byFund.putIfAbsent(fund, () => {'in': 0.0, 'out': 0.0, 'balance': 0.0});
      if (String(t['direction']) == 'IN') {
        totalIn += amt;
        byFund[fund]!['in'] = (byFund[fund]!['in'] ?? 0) + amt;
      } else {
        totalOut += amt;
        byFund[fund]!['out'] = (byFund[fund]!['out'] ?? 0) + amt;
      }
    }

    final byFundOut = <String, dynamic>{};
    byFund.forEach((k, v) {
      final incoming = v['in'] ?? 0;
      final outgoing = v['out'] ?? 0;
      byFundOut[k] = {
        'in': incoming,
        'out': outgoing,
        'balance': incoming - outgoing,
      };
    });

    return {
      'totalIn': totalIn,
      'totalOut': totalOut,
      'balance': totalIn - totalOut,
      'byFund': byFundOut,
    };
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(String(v ?? '').trim()) ?? 0;
  }
}
