import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:googleapis/sheets/v4.dart' as gsheet;
import 'package:googleapis_auth/googleapis_auth.dart';

import '../../core/app_config.dart';
import 'google_auth_service.dart';
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
  };

  static const String _usersSheet = 'users_roles';
  static const String _txnSheet = 'fund_transactions';
  static const String _beneficiariesSheet = 'beneficiaries';
  static const String _staffSheet = 'salary_staff';
  static const String _salarySheet = 'salary_payments';
  static const String _scholarPaySheet = 'scholarship_payments';

  Future<Map<String, dynamic>> get(String action, {Map<String, String>? query}) async {
    final authQuery = _authQuery();
    final scopedQuery = {...authQuery, ...?query};
    final cacheKey = _cacheKey(action, scopedQuery);

    try {
      final res = await _handleGet(action, scopedQuery);
      if (res['ok'] == true) {
        await LocalStoreService.cacheGetResponse(cacheKey, res);
      }
      return res;
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
    try {
      return await _handlePost(action, payload);
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

  Future<Map<String, dynamic>> _handleGet(String action, Map<String, String> query) async {
    switch (action) {
      case 'health':
        return {
          'ok': true,
          'ts': DateTime.now().toIso8601String(),
          'mode': 'direct_google_sheets_oauth',
          'sheetId': AppConfig.googleSheetId,
        };

      case 'hashPin':
        final pin = (query['pin'] ?? '').trim();
        if (pin.isEmpty) return {'ok': false, 'message': 'pin required'};
        return {'ok': true, 'pin_hash': _sha256(pin)};

      case 'listTransactions':
        return _listTransactions(query);

      case 'dashboardSummary':
        return _dashboardSummary(query);

      case 'listUsers':
        return _listUsers(query);

      case 'listBeneficiaries':
        return _listBeneficiaries(query);

      case 'listStaff':
        return _listStaff(query);

      case 'listSalaryPayments':
        return _listSalaryPayments(query);

      case 'listScholarshipByMonth':
        return _listScholarshipByMonth(query);

      case 'monthlyReport':
        return _monthlyReport(query);

      default:
        return {'ok': false, 'message': 'Unknown action'};
    }
  }

  Future<Map<String, dynamic>> _handlePost(String action, Map<String, dynamic> payload) async {
    switch (action) {
      case 'login':
        return _login(payload);

      case 'createTransaction':
        _assertRole(payload['user_role'], const ['ADMIN', 'ACCOUNTANT', 'FIELD_USER']);
        return _createTransaction(Map<String, dynamic>.from(payload['payload'] as Map? ?? {}));

      case 'upsertUser':
        _assertRole(payload['user_role'], const ['ADMIN']);
        return _upsertUser(Map<String, dynamic>.from(payload['payload'] as Map? ?? {}));

      case 'upsertBeneficiary':
        _assertRole(payload['user_role'], const ['ADMIN', 'ACCOUNTANT']);
        return _upsertById(_beneficiariesSheet, Map<String, dynamic>.from(payload['payload'] as Map? ?? {}));

      case 'upsertStaff':
        _assertRole(payload['user_role'], const ['ADMIN', 'ACCOUNTANT']);
        return _upsertById(_staffSheet, Map<String, dynamic>.from(payload['payload'] as Map? ?? {}));

      case 'recordSalaryPayment':
        _assertRole(payload['user_role'], const ['ADMIN', 'ACCOUNTANT']);
        return _recordSalaryPayment(Map<String, dynamic>.from(payload['payload'] as Map? ?? {}));

      case 'saveScholarshipPayment':
        _assertRole(payload['user_role'], const ['ADMIN', 'ACCOUNTANT']);
        return _saveScholarshipPayment(Map<String, dynamic>.from(payload['payload'] as Map? ?? {}));

      default:
        return {'ok': false, 'message': 'Unknown action'};
    }
  }

  Future<Map<String, dynamic>> _login(Map<String, dynamic> payload) async {
    final email = (payload['email'] ?? '').toString().trim().toLowerCase();
    if (email.isEmpty) return {'ok': false, 'message': 'email required'};

    final users = await _readRows(_usersSheet);
    final user = users.firstWhere(
      (u) =>
          (u['email'] ?? '').toString().trim().toLowerCase() == email &&
          (u['active'] ?? '').toString().toUpperCase() == 'TRUE',
      orElse: () => <String, dynamic>{},
    );

    if (user.isEmpty) {
      return {'ok': false, 'message': 'This Gmail is not approved or inactive'};
    }

    return {
      'ok': true,
      'data': {
        'id': (user['id'] ?? '').toString(),
        'name': (user['name'] ?? '').toString(),
        'role': (user['role'] ?? 'VIEWER').toString(),
        'phone': (user['phone'] ?? '').toString(),
        'email': (user['email'] ?? '').toString(),
      },
    };
  }

  Future<Map<String, dynamic>> _listTransactions(Map<String, String> query) async {
    _assertRole(query['user_role'], const ['ADMIN', 'ACCOUNTANT', 'FIELD_USER', 'VIEWER']);
    final role = (query['user_role'] ?? '').trim();
    final userId = (query['user_id'] ?? '').trim();

    if (role == 'VIEWER') return {'ok': true, 'data': <Map<String, dynamic>>[]};

    final rows = await _readRows(_txnSheet, normalizeLegacy: true);
    final fundType = (query['fundType'] ?? '').trim();
    final direction = (query['direction'] ?? '').trim();
    final from = (query['from'] ?? '').trim();
    final to = (query['to'] ?? '').trim();

    final filtered = rows.where((r) {
      if (fundType.isNotEmpty && (r['fund_type'] ?? '').toString() != fundType) return false;
      if (direction.isNotEmpty && (r['direction'] ?? '').toString() != direction) return false;
      final txnDate = (r['txn_date'] ?? '').toString();
      if (from.isNotEmpty && txnDate.compareTo(from) < 0) return false;
      if (to.isNotEmpty && txnDate.compareTo(to) > 0) return false;
      if ((r['status'] ?? 'ACTIVE').toString().toUpperCase() == 'VOID') return false;
      if (role == 'FIELD_USER' && (r['created_by'] ?? '').toString() != userId) return false;
      return true;
    }).toList();

    filtered.sort((a, b) => (b['txn_date'] ?? '').toString().compareTo((a['txn_date'] ?? '').toString()));
    return {'ok': true, 'data': filtered};
  }

  Future<Map<String, dynamic>> _dashboardSummary(Map<String, String> query) async {
    final txRes = await _listTransactions(query);
    if (txRes['ok'] != true) return txRes;

    final txns = ((txRes['data'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final summary = <String, dynamic>{
      'totalIn': 0.0,
      'totalOut': 0.0,
      'balance': 0.0,
      'byFund': <String, dynamic>{},
    };

    for (final t in txns) {
      final amt = _num(t['amount']);
      final fund = (t['fund_type'] ?? 'UNKNOWN').toString();
      final byFund = Map<String, dynamic>.from(summary['byFund'] as Map);
      byFund.putIfAbsent(fund, () => {'in': 0.0, 'out': 0.0, 'balance': 0.0});
      final fundMap = Map<String, dynamic>.from(byFund[fund] as Map);

      if ((t['direction'] ?? '').toString() == 'IN') {
        summary['totalIn'] = _num(summary['totalIn']) + amt;
        fundMap['in'] = _num(fundMap['in']) + amt;
      } else {
        summary['totalOut'] = _num(summary['totalOut']) + amt;
        fundMap['out'] = _num(fundMap['out']) + amt;
      }

      fundMap['balance'] = _num(fundMap['in']) - _num(fundMap['out']);
      byFund[fund] = fundMap;
      summary['byFund'] = byFund;
    }

    summary['balance'] = _num(summary['totalIn']) - _num(summary['totalOut']);
    return {'ok': true, 'data': summary};
  }

  Future<Map<String, dynamic>> _monthlyReport(Map<String, String> query) async {
    final monthKey = (query['monthKey'] ?? '').trim();
    if (monthKey.isEmpty) return {'ok': false, 'message': 'monthKey required'};

    final txRes = await _listTransactions(query);
    if (txRes['ok'] != true) return txRes;

    final txns = ((txRes['data'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final monthly = txns.where((t) => (t['txn_date'] ?? '').toString().startsWith(monthKey)).toList();

    var totalIn = 0.0;
    var totalOut = 0.0;
    for (final t in monthly) {
      final amt = _num(t['amount']);
      if ((t['direction'] ?? '').toString() == 'IN') {
        totalIn += amt;
      } else {
        totalOut += amt;
      }
    }

    final role = (query['user_role'] ?? '').trim();
    final rows = role == 'VIEWER' ? <Map<String, dynamic>>[] : monthly;

    return {
      'ok': true,
      'data': {
        'monthKey': monthKey,
        'totalIn': totalIn,
        'totalOut': totalOut,
        'balance': totalIn - totalOut,
        'rows': rows,
      },
    };
  }

  Future<Map<String, dynamic>> _listBeneficiaries(Map<String, String> query) async {
    _assertRole(query['user_role'], const ['ADMIN', 'ACCOUNTANT', 'VIEWER']);
    final rows = await _readRows(_beneficiariesSheet, normalizeLegacy: true);
    return {'ok': true, 'data': rows};
  }

  Future<Map<String, dynamic>> _listUsers(Map<String, String> query) async {
    _assertRole(query['user_role'], const ['ADMIN']);
    final rows = await _readRows(_usersSheet);
    final sanitized = rows.map((u) {
      final row = Map<String, dynamic>.from(u);
      row.remove('pin_hash');
      return row;
    }).toList();
    return {'ok': true, 'data': sanitized};
  }

  Future<Map<String, dynamic>> _upsertUser(Map<String, dynamic> payload) async {
    final email = (payload['email'] ?? '').toString().trim().toLowerCase();
    final name = (payload['name'] ?? '').toString().trim();
    final role = (payload['role'] ?? 'VIEWER').toString().trim();
    final allowedRoles = {'ADMIN', 'ACCOUNTANT', 'FIELD_USER', 'VIEWER'};

    if (email.isEmpty || name.isEmpty) {
      return {'ok': false, 'message': 'name and email required'};
    }
    if (!allowedRoles.contains(role)) {
      return {'ok': false, 'message': 'invalid role'};
    }

    final id = (payload['id'] ?? '').toString().trim();
    final createId = id.isNotEmpty ? id : 'u_${DateTime.now().millisecondsSinceEpoch}';

    final userPayload = {
      'id': createId,
      'name': name,
      'phone': (payload['phone'] ?? '').toString().trim(),
      'email': email,
      'role': role,
      'active': ((payload['active'] ?? 'TRUE').toString().toUpperCase() == 'FALSE') ? 'FALSE' : 'TRUE',
      'pin_hash': (payload['pin_hash'] ?? '').toString(),
    };

    final res = await _upsertById(_usersSheet, userPayload);
    if (res['ok'] == true && res['data'] is Map) {
      final data = Map<String, dynamic>.from(res['data'] as Map);
      data.remove('pin_hash');
      res['data'] = data;
    }
    return res;
  }

  Future<Map<String, dynamic>> _listStaff(Map<String, String> query) async {
    _assertRole(query['user_role'], const ['ADMIN', 'ACCOUNTANT', 'VIEWER']);
    final rows = await _readRows(_staffSheet);
    return {'ok': true, 'data': rows};
  }

  Future<Map<String, dynamic>> _listSalaryPayments(Map<String, String> query) async {
    _assertRole(query['user_role'], const ['ADMIN', 'ACCOUNTANT', 'VIEWER']);
    final monthKey = (query['monthKey'] ?? '').trim();
    final staffId = (query['staffId'] ?? '').trim();

    final rows = await _readRows(_salarySheet);
    final filtered = rows.where((r) {
      if (monthKey.isNotEmpty && (r['month_key'] ?? '').toString() != monthKey) return false;
      if (staffId.isNotEmpty && (r['staff_id'] ?? '').toString() != staffId) return false;
      return true;
    }).toList();

    filtered.sort((a, b) => (b['payment_date'] ?? '').toString().compareTo((a['payment_date'] ?? '').toString()));
    return {'ok': true, 'data': filtered};
  }

  Future<Map<String, dynamic>> _listScholarshipByMonth(Map<String, String> query) async {
    _assertRole(query['user_role'], const ['ADMIN', 'ACCOUNTANT', 'VIEWER']);
    final monthKey = (query['monthKey'] ?? '').trim();
    final beneficiaryId = (query['beneficiaryId'] ?? '').trim();

    final rows = await _readRows(_scholarPaySheet, normalizeLegacy: true);
    final filtered = rows.where((r) {
      if (monthKey.isNotEmpty && (r['month_key'] ?? '').toString() != monthKey) return false;
      if (beneficiaryId.isNotEmpty && (r['beneficiary_id'] ?? '').toString() != beneficiaryId) return false;
      return true;
    }).toList();

    filtered.sort((a, b) => (b['payment_date'] ?? '').toString().compareTo((a['payment_date'] ?? '').toString()));
    return {'ok': true, 'data': filtered};
  }

  Future<Map<String, dynamic>> _createTransaction(Map<String, dynamic> payload) async {
    final row = {
      'id': (payload['id'] ?? 'txn_${DateTime.now().millisecondsSinceEpoch}').toString(),
      'txn_date': (payload['txn_date'] ?? '').toString(),
      'direction': (payload['direction'] ?? '').toString(),
      'fund_type': (payload['fund_type'] ?? '').toString(),
      'amount': _num(payload['amount']),
      'source_or_vendor': (payload['source_or_vendor'] ?? '').toString(),
      'category': (payload['category'] ?? '').toString(),
      'reference': (payload['reference'] ?? '').toString(),
      'notes': (payload['notes'] ?? '').toString(),
      'related_entity_type': (payload['related_entity_type'] ?? '').toString(),
      'related_entity_id': (payload['related_entity_id'] ?? '').toString(),
      'status': (payload['status'] ?? 'ACTIVE').toString(),
      'created_by': (payload['created_by'] ?? SessionService.userId).toString(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (row['txn_date']!.isEmpty) return {'ok': false, 'message': 'txn_date required'};
    if (row['direction']!.isEmpty) return {'ok': false, 'message': 'direction required'};
    if (row['fund_type']!.isEmpty) return {'ok': false, 'message': 'fund_type required'};
    if (_num(row['amount']) <= 0) return {'ok': false, 'message': 'amount must be > 0'};

    await _appendByHeaders(_txnSheet, row);
    return {'ok': true, 'data': row};
  }

  Future<Map<String, dynamic>> _upsertById(String sheetName, Map<String, dynamic> payload) async {
    final id = (payload['id'] ?? '').toString().trim();
    if (id.isEmpty) return {'ok': false, 'message': 'id required'};

    final table = await _readTable(sheetName);
    final idIndex = table.headers.indexOf('id');
    if (idIndex == -1) return {'ok': false, 'message': 'No id column in $sheetName'};

    int matchedRow = -1;
    List<dynamic> matched = [];
    for (var i = 0; i < table.rawRows.length; i++) {
      final row = table.rawRows[i];
      final v = idIndex < row.length ? row[idIndex] : '';
      if (v.toString() == id) {
        matchedRow = i;
        matched = row;
        break;
      }
    }

    final now = DateTime.now().toIso8601String();
    if (matchedRow == -1) {
      final createObj = {...payload};
      createObj['created_at'] = createObj['created_at'] ?? now;
      createObj['updated_at'] = now;
      await _appendByHeaders(sheetName, createObj);
      return {'ok': true, 'mode': 'create', 'data': createObj};
    }

    final current = _rowToObj(table.headers, matched);
    final after = <String, dynamic>{...current, ...payload, 'updated_at': now};
    final writeRow = table.headers.map((h) => after[h] ?? '').toList();

    final api = await _sheetsApi();
    final rowNumber = matchedRow + 2;
    await api.spreadsheets.values.update(
      gsheet.ValueRange(values: [writeRow]),
      AppConfig.googleSheetId,
      '$sheetName!A$rowNumber:Z$rowNumber',
      valueInputOption: 'RAW',
    );

    return {'ok': true, 'mode': 'update', 'data': after};
  }

  Future<Map<String, dynamic>> _recordSalaryPayment(Map<String, dynamic> payload) async {
    final row = {
      'id': (payload['id'] ?? 'salpay_${DateTime.now().millisecondsSinceEpoch}').toString(),
      'staff_id': (payload['staff_id'] ?? '').toString(),
      'month_key': (payload['month_key'] ?? '').toString(),
      'payable_amount': _num(payload['payable_amount']),
      'paid_amount': _num(payload['paid_amount']),
      'due_amount': _num(payload['due_amount']),
      'payment_date': (payload['payment_date'] ?? _todayIso()).toString(),
      'txn_id': (payload['txn_id'] ?? '').toString(),
      'status': (payload['status'] ?? 'PAID').toString(),
      'notes': (payload['notes'] ?? '').toString(),
    };

    if (row['staff_id']!.isEmpty || row['month_key']!.isEmpty) {
      return {'ok': false, 'message': 'staff_id and month_key required'};
    }

    await _appendByHeaders(_salarySheet, row);

    final txn = await _createTransaction({
      'txn_date': row['payment_date'],
      'direction': 'OUT',
      'fund_type': (payload['fund_type'] ?? 'GENERAL').toString(),
      'amount': row['paid_amount'],
      'source_or_vendor': (payload['staff_name'] ?? 'Salary Payment').toString(),
      'category': 'SALARY',
      'notes': row['notes'],
      'related_entity_type': 'SALARY',
      'related_entity_id': row['id'],
      'created_by': (payload['created_by'] ?? SessionService.userId).toString(),
    });

    return {'ok': true, 'salary': row, 'transaction': txn['data']};
  }

  Future<Map<String, dynamic>> _saveScholarshipPayment(Map<String, dynamic> payload) async {
    final row = {
      'id': (payload['id'] ?? 'schpay_${DateTime.now().millisecondsSinceEpoch}').toString(),
      'month_key': (payload['month_key'] ?? '').toString(),
      'beneficiary_id': (payload['beneficiary_id'] ?? '').toString(),
      'school_fee': _num(payload['school_fee']),
      'bangla_tutor': _num(payload['bangla_tutor']),
      'arabi_tutor': _num(payload['arabi_tutor']),
      'materials': _num(payload['materials']),
      'other': _num(payload['other']),
      'total_paid': _num(payload['total_paid']),
      'remaining_amount': _num(payload['remaining_amount']),
      'payment_date': (payload['payment_date'] ?? _todayIso()).toString(),
      'payment_status': (payload['payment_status'] ?? 'PAID').toString(),
      'txn_id': (payload['txn_id'] ?? '').toString(),
      'notes': (payload['notes'] ?? '').toString(),
    };

    if (row['month_key']!.isEmpty || row['beneficiary_id']!.isEmpty) {
      return {'ok': false, 'message': 'month_key and beneficiary_id required'};
    }

    await _appendByHeaders(_scholarPaySheet, row);

    final txn = await _createTransaction({
      'txn_date': row['payment_date'],
      'direction': 'OUT',
      'fund_type': (payload['fund_type'] ?? 'SCHOLARSHIP').toString(),
      'amount': row['total_paid'],
      'source_or_vendor': (payload['beneficiary_name'] ?? 'Scholarship Payment').toString(),
      'category': 'SCHOLARSHIP_PAYMENT',
      'notes': row['notes'],
      'related_entity_type': 'SCHOLARSHIP_PAYMENT',
      'related_entity_id': row['id'],
      'created_by': (payload['created_by'] ?? SessionService.userId).toString(),
    });

    return {'ok': true, 'scholarshipPayment': row, 'transaction': txn['data']};
  }

  Future<List<Map<String, dynamic>>> _readRows(String sheetName, {bool normalizeLegacy = false}) async {
    final table = await _readTable(sheetName);
    final rows = table.rawRows.map((r) => _rowToObj(table.headers, r)).toList();

    if (!normalizeLegacy) return rows;

    if (sheetName == _txnSheet) {
      return rows.map(_normalizeLegacyTxn).toList();
    }
    if (sheetName == _beneficiariesSheet) {
      return rows.map(_normalizeLegacyBeneficiary).toList();
    }
    if (sheetName == _scholarPaySheet) {
      return rows.map(_normalizeLegacyScholarPay).toList();
    }

    return rows;
  }

  Future<_TableData> _readTable(String sheetName) async {
    final api = await _sheetsApi();
    final res = await api.spreadsheets.values.get(
      AppConfig.googleSheetId,
      '$sheetName!A1:Z',
    );

    final values = res.values ?? [];
    if (values.isEmpty) {
      return const _TableData(headers: [], rawRows: []);
    }

    final headers = values.first.map((e) => e.toString()).toList();
    final rawRows = <List<dynamic>>[];

    for (final r in values.skip(1)) {
      final row = r.toList();
      final nonEmpty = row.any((v) => v.toString().trim().isNotEmpty);
      if (nonEmpty) rawRows.add(row);
    }

    return _TableData(headers: headers, rawRows: rawRows);
  }

  Map<String, dynamic> _rowToObj(List<String> headers, List<dynamic> row) {
    final out = <String, dynamic>{};
    for (var i = 0; i < headers.length; i++) {
      out[headers[i]] = i < row.length ? row[i] : '';
    }
    return out;
  }

  Future<void> _appendByHeaders(String sheetName, Map<String, dynamic> obj) async {
    final table = await _readTable(sheetName);
    if (table.headers.isEmpty) {
      throw Exception('Sheet $sheetName has no header row');
    }
    final row = table.headers.map((h) => obj[h] ?? '').toList();

    final api = await _sheetsApi();
    await api.spreadsheets.values.append(
      gsheet.ValueRange(values: [row]),
      AppConfig.googleSheetId,
      '$sheetName!A:Z',
      valueInputOption: 'RAW',
      insertDataOption: 'INSERT_ROWS',
    );
  }

  Future<gsheet.SheetsApi> _sheetsApi() async {
    final AuthClient? client = await GoogleAuthService.authClient();
    if (client == null) throw Exception('Google authorization required');
    return gsheet.SheetsApi(client);
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

  void _assertRole(dynamic roleValue, List<String> allowed) {
    final role = (roleValue ?? '').toString();
    if (role.isEmpty || !allowed.contains(role)) {
      throw Exception('Permission denied for role: $role');
    }
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  String _todayIso() {
    final d = DateTime.now();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse((v ?? '').toString().trim()) ?? 0;
  }

  bool _isDateLike(String s) {
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s);
  }

  Map<String, dynamic> _normalizeLegacyTxn(Map<String, dynamic> r) {
    final txnDate = (r['txn_date'] ?? '').toString();
    final direction = (r['direction'] ?? '').toString();
    final fundType = (r['fund_type'] ?? '').toString();
    final id = (r['id'] ?? '').toString();

    final dirSet = {'IN', 'OUT'};
    final fundSet = {'CONSTRUCTION', 'JAKAT', 'SCHOLARSHIP', 'GENERAL'};

    if (dirSet.contains(txnDate) && fundSet.contains(direction) && _num(fundType) > 0 && _isDateLike(id)) {
      return {
        ...r,
        'id': (r['id'] ?? '').toString().startsWith('txn_') ? r['id'] : 'legacy_${id}_${direction}_${fundType}',
        'txn_date': id,
        'direction': txnDate,
        'fund_type': direction,
        'amount': _num(fundType),
        'source_or_vendor': (r['amount'] ?? '').toString(),
        'category': (r['source_or_vendor'] ?? '').toString(),
        'notes': (r['category'] ?? '').toString(),
        'status': (r['status'] ?? 'ACTIVE').toString().isEmpty ? 'ACTIVE' : r['status'].toString(),
      };
    }

    return {
      ...r,
      'status': (r['status'] ?? 'ACTIVE').toString().isEmpty ? 'ACTIVE' : r['status'].toString(),
      'amount': _num(r['amount']),
    };
  }

  Map<String, dynamic> _normalizeLegacyBeneficiary(Map<String, dynamic> r) {
    final serialNo = (r['serial_no'] ?? '').toString();
    final nameBn = (r['name_bn'] ?? '').toString();
    final age = (r['age'] ?? '').toString();

    if (serialNo.isNotEmpty && nameBn.isNotEmpty && age.isNotEmpty && double.tryParse(nameBn) != null) {
      return {
        ...r,
        'id': (r['id'] ?? '').toString(),
        'serial_no': (r['id'] ?? '').toString(),
        'name_bn': serialNo,
        'age': nameBn,
        'guardian_status': age,
        'class_name': (r['guardian_status'] ?? '').toString(),
        'primary_need': (r['class_name'] ?? '').toString(),
        'monthly_need': (r['primary_need'] ?? '').toString(),
        'monthly_need_amount': _num(r['monthly_need']),
        'active': (r['monthly_need_amount'] ?? 'TRUE').toString().isEmpty ? 'TRUE' : r['monthly_need_amount'].toString(),
      };
    }

    return {
      ...r,
      'monthly_need_amount': _num(r['monthly_need_amount']),
      'active': (r['active'] ?? 'TRUE').toString(),
    };
  }

  Map<String, dynamic> _normalizeLegacyScholarPay(Map<String, dynamic> r) {
    final monthKey = (r['id'] ?? '').toString();
    final beneficiary = (r['month_key'] ?? '').toString();
    final schoolFee = _num(r['beneficiary_id']);

    if (monthKey.startsWith('20') && beneficiary.isNotEmpty && schoolFee >= 0 && (r['payment_status'] ?? '').toString().isEmpty) {
      return {
        ...r,
        'id': 'legacy_${monthKey}_${beneficiary}',
        'month_key': monthKey,
        'beneficiary_id': beneficiary,
        'school_fee': schoolFee,
        'bangla_tutor': _num(r['school_fee']),
        'arabi_tutor': _num(r['bangla_tutor']),
        'materials': _num(r['arabi_tutor']),
        'other': _num(r['materials']),
        'total_paid': _num(r['other']),
        'remaining_amount': _num(r['total_paid']),
        'payment_status': (r['remaining_amount'] ?? 'PAID').toString(),
        'payment_date': '',
        'txn_id': '',
        'notes': (r['notes'] ?? 'migrated').toString(),
      };
    }

    return {
      ...r,
      'school_fee': _num(r['school_fee']),
      'bangla_tutor': _num(r['bangla_tutor']),
      'arabi_tutor': _num(r['arabi_tutor']),
      'materials': _num(r['materials']),
      'other': _num(r['other']),
      'total_paid': _num(r['total_paid']),
      'remaining_amount': _num(r['remaining_amount']),
      'payment_status': (r['payment_status'] ?? 'PAID').toString(),
    };
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
          .where((r) => monthKey.isEmpty || (r['txn_date'] ?? '').toString().startsWith(monthKey))
          .toList();
      var totalIn = 0.0;
      var totalOut = 0.0;
      for (final t in txns) {
        final amt = _num(t['amount']);
        if ((t['direction'] ?? '').toString() == 'IN') {
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

    if (action == 'listUsers') {
      final list = _queuedActionPayloads('upsertUser')
          .map((p) {
            final envelope = Map<String, dynamic>.from(p['payload'] as Map? ?? {});
            final row = Map<String, dynamic>.from(envelope['payload'] as Map? ?? {});
            row.remove('pin_hash');
            return row;
          })
          .toList();
      return {'ok': true, 'data': list};
    }

    if (action == 'listBeneficiaries') {
      final list = _queuedActionPayloads('upsertBeneficiary')
          .map((p) {
            final envelope = Map<String, dynamic>.from(p['payload'] as Map? ?? {});
            return Map<String, dynamic>.from(envelope['payload'] as Map? ?? {});
          })
          .toList();
      return {'ok': true, 'data': list};
    }

    if (action == 'listStaff') {
      final list = _queuedActionPayloads('upsertStaff')
          .map((p) {
            final envelope = Map<String, dynamic>.from(p['payload'] as Map? ?? {});
            return Map<String, dynamic>.from(envelope['payload'] as Map? ?? {});
          })
          .toList();
      return {'ok': true, 'data': list};
    }

    if (action == 'listSalaryPayments') {
      final list = _queuedActionPayloads('recordSalaryPayment')
          .map((p) {
            final envelope = Map<String, dynamic>.from(p['payload'] as Map? ?? {});
            return Map<String, dynamic>.from(envelope['payload'] as Map? ?? {});
          })
          .toList();
      return {'ok': true, 'data': list};
    }

    if (action == 'listScholarshipByMonth') {
      final monthKey = (query['monthKey'] ?? '').trim();
      final list = _queuedActionPayloads('saveScholarshipPayment')
          .map((p) {
            final envelope = Map<String, dynamic>.from(p['payload'] as Map? ?? {});
            return Map<String, dynamic>.from(envelope['payload'] as Map? ?? {});
          })
          .where((r) => monthKey.isEmpty || (r['month_key'] ?? '').toString() == monthKey)
          .toList();
      return {'ok': true, 'data': list};
    }

    return null;
  }

  List<Map<String, dynamic>> _queuedActionPayloads(String action) {
    final queue = LocalStoreService.getPendingPosts();
    return queue
        .where((item) => (item['action'] ?? '').toString() == action)
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
      if (role == 'FIELD_USER' && (r['created_by'] ?? '').toString() != userId) return false;
      if (role == 'VIEWER') return false;
      if (direction.isNotEmpty && (r['direction'] ?? '').toString() != direction) return false;
      if (fundType.isNotEmpty && (r['fund_type'] ?? '').toString() != fundType) return false;
      final d = (r['txn_date'] ?? '').toString();
      if (from.isNotEmpty && d.compareTo(from) < 0) return false;
      if (to.isNotEmpty && d.compareTo(to) > 0) return false;
      return true;
    }).toList();

    scoped.sort((a, b) => (b['txn_date'] ?? '').toString().compareTo((a['txn_date'] ?? '').toString()));
    return scoped;
  }

  Map<String, dynamic> _summaryFromLocalQueue(Map<String, String> query) {
    final txns = _queuedTransactions(query);
    final byFund = <String, Map<String, double>>{};
    var totalIn = 0.0;
    var totalOut = 0.0;

    for (final t in txns) {
      final fund = (t['fund_type'] ?? 'UNKNOWN').toString();
      final amt = _num(t['amount']);
      byFund.putIfAbsent(fund, () => {'in': 0.0, 'out': 0.0, 'balance': 0.0});
      if ((t['direction'] ?? '').toString() == 'IN') {
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
}

class _TableData {
  final List<String> headers;
  final List<List<dynamic>> rawRows;
  const _TableData({required this.headers, required this.rawRows});
}
