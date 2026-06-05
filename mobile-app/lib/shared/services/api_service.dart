import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/app_config.dart';
import '../constants/app_permissions.dart';
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
    'publishNotice',
    'markNoticeRead',
    'upsertDocument',
    'upsertUser',
    'setUserApprovalStatus',
  };

  static const Map<String, Duration> _readCacheTtlByAction = {
    'dashboardSummary': Duration(minutes: 10),
    'monthlyReport': Duration(minutes: 10),
    'rangeReport': Duration(minutes: 10),
    'datasetStats': Duration(minutes: 20),
    'listTransactions': Duration(minutes: 10),
    'listBeneficiaries': Duration(hours: 1),
    'listStaff': Duration(hours: 1),
    'listSalaryPayments': Duration(minutes: 20),
    'listScholarshipByMonth': Duration(minutes: 20),
    'listStudents': Duration(hours: 1),
    'listStudentGuardians': Duration(hours: 1),
    'listClasses': Duration(hours: 6),
    'listSections': Duration(hours: 6),
    'listSubjects': Duration(hours: 6),
    'getAppUiSettings': Duration(hours: 6),
    'listInAppNotifications': Duration(minutes: 5),
    'getNotificationSettings': Duration(minutes: 30),
    'listFeePlans': Duration(minutes: 30),
    'listFeeDues': Duration(minutes: 10),
    'listUsers': Duration(minutes: 15),
    'listDocuments': Duration(minutes: 15),
    'listNotices': Duration(minutes: 15),
    'listAuditLog': Duration(minutes: 5),
    'listRoleDefinitions': Duration(hours: 1),
  };

  static const Map<String, String> _actionPermissions = {
    'dashboardSummary': AppPermissions.dashboardView,
    'listTransactions': AppPermissions.donationsView,
    'listBeneficiaries': AppPermissions.beneficiariesView,
    'listStaff': AppPermissions.salaryView,
    'listSalaryPayments': AppPermissions.salaryView,
    'listScholarshipByMonth': AppPermissions.scholarshipView,
    'listStudents': AppPermissions.academicFoundationView,
    'listStudentGuardians': AppPermissions.academicFoundationView,
    'listClasses': AppPermissions.academicFoundationView,
    'listSections': AppPermissions.academicFoundationView,
    'listSubjects': AppPermissions.academicFoundationView,
    'listAttendance': AppPermissions.academicCoreView,
    'listExamTerms': AppPermissions.academicCoreView,
    'listExamMarks': AppPermissions.academicCoreView,
    'resultSummary': AppPermissions.academicCoreView,
    'listFeePlans': AppPermissions.feesView,
    'listFeePayments': AppPermissions.feesView,
    'listFeeWaivers': AppPermissions.feesView,
    'listFeeDues': AppPermissions.feesView,
    'listBudgets': AppPermissions.financeView,
    'financeControlSummary': AppPermissions.financeView,
    'listApprovalRules': AppPermissions.financeView,
    'listApprovalRequests': AppPermissions.financeView,
    'listNotices': AppPermissions.communicationView,
    'listDocuments': AppPermissions.communicationView,
    'monthlyReport': AppPermissions.reportsView,
    'rangeReport': AppPermissions.reportsView,
    'datasetStats': AppPermissions.reportsView,
    'getAppUiSettings': AppPermissions.reportsView,
    'listAuditLog': AppPermissions.auditView,
    'getNotificationSettings': AppPermissions.notificationsManage,
    'listInAppNotifications': AppPermissions.notificationsView,
    'listRoleDefinitions': AppPermissions.rolesView,
    'createTransaction': AppPermissions.donationsWrite,
    'updateTransaction': AppPermissions.transactionsManage,
    'upsertBeneficiary': AppPermissions.beneficiariesWrite,
    'upsertStaff': AppPermissions.salaryWrite,
    'recordSalaryPayment': AppPermissions.salaryWrite,
    'saveScholarshipPayment': AppPermissions.scholarshipWrite,
    'upsertStudent': AppPermissions.academicFoundationWrite,
    'upsertStudentGuardian': AppPermissions.academicFoundationWrite,
    'upsertClass': AppPermissions.academicFoundationWrite,
    'upsertSection': AppPermissions.academicFoundationWrite,
    'upsertSubject': AppPermissions.academicFoundationWrite,
    'saveAttendance': AppPermissions.academicAttendanceWrite,
    'upsertExamTerm': AppPermissions.academicCoreWrite,
    'saveExamMark': AppPermissions.academicCoreWrite,
    'upsertFeePlan': AppPermissions.feesWrite,
    'recordFeePayment': AppPermissions.feesWrite,
    'upsertFeeWaiver': AppPermissions.feesWrite,
    'upsertBudget': AppPermissions.financeWrite,
    'upsertApprovalRule': AppPermissions.financeApprovalRulesManage,
    'createApprovalRequest': AppPermissions.financeApprovalRequestsCreate,
    'decideApprovalRequest': AppPermissions.financeApprovalRequestsDecide,
    'publishNotice': AppPermissions.communicationWrite,
    'markNoticeRead': AppPermissions.communicationView,
    'upsertDocument': AppPermissions.communicationWrite,
    'listUsers': AppPermissions.usersManage,
    'upsertUser': AppPermissions.usersManage,
    'setUserApprovalStatus': AppPermissions.usersManage,
    'generateTempResetToken': AppPermissions.usersManage,
    'upsertNotificationSettings': AppPermissions.notificationsManage,
    'upsertAppUiSettings': AppPermissions.appUiManage,
    'createNotificationEvent': AppPermissions.notificationsView,
    'upsertRoleDefinition': AppPermissions.rolesManage,
    'logClientGuard': AppPermissions.notificationsView,
  };

  static const Duration _defaultReadCacheTtl = Duration(minutes: 30);

  static const Map<String, Set<String>> _cacheInvalidationsByMutation = {
    'createTransaction': {
      'dashboardSummary',
      'monthlyReport',
      'rangeReport',
      'listTransactions',
      'datasetStats',
    },
    'upsertBeneficiary': {
      'listBeneficiaries',
      'listScholarshipByMonth',
    },
    'upsertStaff': {
      'listStaff',
      'listSalaryPayments',
    },
    'recordSalaryPayment': {
      'dashboardSummary',
      'monthlyReport',
      'rangeReport',
      'listTransactions',
      'datasetStats',
      'listSalaryPayments',
    },
    'saveScholarshipPayment': {
      'dashboardSummary',
      'monthlyReport',
      'rangeReport',
      'listTransactions',
      'datasetStats',
      'listScholarshipByMonth',
    },
    'upsertStudent': {'listStudents', 'listFeeDues'},
    'upsertStudentGuardian': {'listStudentGuardians'},
    'upsertClass': {'listClasses', 'listSections', 'listSubjects', 'listStudents'},
    'upsertSection': {'listSections', 'listStudents'},
    'upsertSubject': {'listSubjects'},
    'upsertFeePlan': {'listFeePlans', 'listFeeDues'},
    'recordFeePayment': {'listFeeDues'},
    'upsertFeeWaiver': {'listFeeDues'},
    'publishNotice': {'listInAppNotifications'},
    'markNoticeRead': {'listInAppNotifications'},
    'upsertDocument': {'listDocuments'},
    'upsertUser': {'listUsers'},
    'setUserApprovalStatus': {'listUsers'},
    'upsertRoleDefinition': {'listRoleDefinitions', 'listUsers'},
  };

  static String hashPin(String pin) {
    final bytes = utf8.encode(pin.trim());
    return sha256.convert(bytes).toString();
  }

  bool get _isConfigured => !AppConfig.isUsingPlaceholderUrl;

  Future<Map<String, dynamic>> _postToAppsScript(
    Map<String, dynamic> payload,
  ) async {
    final client = http.Client();
    try {
      final req = http.Request('POST', Uri.parse(AppConfig.appsScriptUrl))
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
        final res = await client
            .get(Uri.parse(location))
            .timeout(const Duration(seconds: 20));
        if (res.statusCode == 200) {
          return jsonDecode(res.body) as Map<String, dynamic>;
        }
        throw Exception('Redirect GET HTTP ${res.statusCode}');
      }

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
    bool forceRefresh = false,
  }) async {
    final isReadOnly = !_queueableActions.contains(action);
    final cacheKey = _cacheKeyFor(action, body);
    final requiredPermission = _actionPermissions[action];

    if (requiredPermission != null &&
        SessionService.isLoggedIn &&
        !SessionService.can(requiredPermission)) {
      return {
        'ok': false,
        'permission_denied': true,
        'message': 'আপনার এই কাজের অনুমতি নেই',
      };
    }

    if (!_isConfigured) {
      final cached = LocalStoreService.readCachedGetResponse(
        cacheKey,
        allowExpired: true,
      );
      if (cached != null) {
        return _decorateReadResponse(
          action,
          body,
          cached,
          cached: true,
          offline: true,
          stale: true,
        );
      }
      return {
        'ok': false,
        'message':
            'Apps Script URL সেট করা হয়নি। APPS_SCRIPT_URL / API_BASE_URL / APPS_SCRIPT_DEPLOYMENT_ID dart-define দিন।',
      };
    }

    if (isReadOnly && !forceRefresh) {
      final cached = LocalStoreService.readCachedGetResponse(
        cacheKey,
        maxAge: _readCacheTtl(action),
      );
      if (cached != null) {
        return _decorateReadResponse(
          action,
          body,
          cached,
          cached: true,
        );
      }
    }

    try {
      final decoded = await _postToAppsScript({'action': action, ...body});
      if (decoded['ok'] == true && isReadOnly) {
        await LocalStoreService.cacheGetResponse(cacheKey, decoded);
        return _decorateReadResponse(action, body, decoded);
      }
      if (decoded['ok'] == true && !isReadOnly) {
        await LocalStoreService.invalidateGetCache(
          actionPrefixes: _cacheInvalidationsByMutation[action],
        );
      }
      return decoded;
    } catch (e) {
      if (isReadOnly) {
        final cached = LocalStoreService.readCachedGetResponse(
          cacheKey,
          allowExpired: true,
        );
        if (cached != null) {
          return _decorateReadResponse(
            action,
            body,
            cached,
            offline: true,
            cached: true,
            stale: true,
          );
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

  String _cacheKeyFor(String action, Map<String, dynamic> body) =>
      '${action}_${jsonEncode(_stableSort(body))}';

  Duration _readCacheTtl(String action) =>
      _readCacheTtlByAction[action] ?? _defaultReadCacheTtl;

  Map<String, dynamic> _stableSort(Map<String, dynamic> map) {
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Future<Map<String, dynamic>> get(
    String action, {
    Map<String, dynamic>? query,
    bool forceRefresh = false,
  }) {
    return _send(
      action,
      {
        'user_role': SessionService.role,
        'user_id': SessionService.userId,
        ...?query,
      },
      forceRefresh: forceRefresh,
    );
  }

  Future<Map<String, dynamic>> post(
    String action,
    Map<String, dynamic> payload, {
    bool allowQueue = true,
  }) {
    return _send(action, payload, allowQueue: allowQueue);
  }

  Map<String, dynamic> _decorateReadResponse(
    String action,
    Map<String, dynamic> body,
    Map<String, dynamic> source, {
    bool cached = false,
    bool stale = false,
    bool offline = false,
  }) {
    final result = Map<String, dynamic>.from(source);
    if (result['ok'] == true) {
      result['data'] = _applyPendingOverlay(action, body, result['data']);
    }
    if (cached) result['cached'] = true;
    if (stale) result['stale'] = true;
    if (offline) result['offline'] = true;
    return result;
  }

  dynamic _applyPendingOverlay(
      String action, Map<String, dynamic> body, dynamic data) {
    final queue = LocalStoreService.getPendingPosts();
    if (queue.isEmpty) return data;

    switch (action) {
      case 'listTransactions':
        return _overlayTransactions(body, data, queue);
      case 'dashboardSummary':
        return _overlayDashboardSummary(body, data, queue);
      case 'monthlyReport':
        return _overlayMonthlyReport(body, data, queue);
      case 'rangeReport':
        return _overlayRangeReport(body, data, queue);
      case 'datasetStats':
        return _overlayDatasetStats(data, queue);
      case 'listBeneficiaries':
        return _overlaySimpleList(
          data,
          queue,
          targetAction: 'upsertBeneficiary',
          mapItem: _pendingBeneficiary,
        );
      case 'listStaff':
        return _overlaySimpleList(
          data,
          queue,
          targetAction: 'upsertStaff',
          mapItem: _pendingStaff,
        );
      case 'listSalaryPayments':
        return _overlaySimpleList(
          data,
          queue,
          targetAction: 'recordSalaryPayment',
          mapItem: _pendingSalaryPayment,
          filter: (item) =>
              _matchesOptional(item['month_key'], body['monthKey']) &&
              _matchesOptional(item['staff_id'], body['staffId']),
        );
      case 'listScholarshipByMonth':
        return _overlaySimpleList(
          data,
          queue,
          targetAction: 'saveScholarshipPayment',
          mapItem: _pendingScholarshipPayment,
          filter: (item) =>
              _matchesOptional(item['month_key'], body['monthKey']) &&
              _matchesOptional(item['beneficiary_id'], body['beneficiaryId']),
        );
      case 'listStudents':
        return _overlaySimpleList(
          data,
          queue,
          targetAction: 'upsertStudent',
          mapItem: _pendingStudent,
          filter: (item) {
            final classId = _string(item['class_id']);
            final sectionId = _string(item['section_id']);
            final status = _string(item['status']).toUpperCase();
            final search = _string(body['search']).toLowerCase();
            if (!_matchesOptional(classId, body['class_id'])) return false;
            if (!_matchesOptional(sectionId, body['section_id'])) return false;
            if (body['status'] != null &&
                status != _string(body['status']).toUpperCase()) {
              return false;
            }
            if (search.isEmpty) return true;
            final hay = [
              item['student_code'],
              item['name_bn'],
              item['name_en'],
              item['roll_no'],
              item['phone'],
            ].join(' ').toLowerCase();
            return hay.contains(search);
          },
        );
      case 'listStudentGuardians':
        return _overlaySimpleList(
          data,
          queue,
          targetAction: 'upsertStudentGuardian',
          mapItem: _pendingGuardian,
          filter: (item) => _matchesOptional(item['student_id'], body['student_id']),
        );
      case 'listClasses':
        return _overlaySimpleList(
          data,
          queue,
          targetAction: 'upsertClass',
          mapItem: _pendingClass,
        );
      case 'listSections':
        return _overlaySimpleList(
          data,
          queue,
          targetAction: 'upsertSection',
          mapItem: _pendingSection,
          filter: (item) => _matchesOptional(item['class_id'], body['class_id']),
        );
      case 'listSubjects':
        return _overlaySimpleList(
          data,
          queue,
          targetAction: 'upsertSubject',
          mapItem: _pendingSubject,
          filter: (item) => _matchesOptional(item['class_id'], body['class_id']),
        );
      case 'listFeePlans':
        return _overlaySimpleList(
          data,
          queue,
          targetAction: 'upsertFeePlan',
          mapItem: _pendingFeePlan,
        );
      default:
        return data;
    }
  }

  List<Map<String, dynamic>> _overlayTransactions(
    Map<String, dynamic> body,
    dynamic data,
    List<Map<String, dynamic>> queue,
  ) {
    final rows = (data as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final pending = queue
        .map(_pendingTransactionFromQueuedAction)
        .whereType<Map<String, dynamic>>()
        .where((item) => _matchesTransactionQuery(item, body))
        .toList();
    return _mergeRows(rows, pending, sortByDateField: 'txn_date');
  }

  Map<String, dynamic> _overlayDashboardSummary(
    Map<String, dynamic> body,
    dynamic data,
    List<Map<String, dynamic>> queue,
  ) {
    final summary = Map<String, dynamic>.from(data as Map? ?? {});
    final from = _string(body['from']);
    final to = _string(body['to']);
    final byFund = Map<String, dynamic>.from(summary['byFund'] as Map? ?? {});
    var totalIn = _toDouble(summary['totalIn']);
    var totalOut = _toDouble(summary['totalOut']);

    for (final txn in queue
        .map(_pendingTransactionFromQueuedAction)
        .whereType<Map<String, dynamic>>()) {
      if (!_inDateRange(_string(txn['txn_date']), from, to)) continue;
      final fund = _string(txn['fund_type']).toUpperCase();
      final dir = _string(txn['direction']).toUpperCase();
      final amount = _toDouble(txn['amount']);
      final bucket = Map<String, dynamic>.from(byFund[fund] as Map? ?? {});
      final currentIn = _toDouble(bucket['in']);
      final currentOut = _toDouble(bucket['out']);
      if (dir == 'IN') {
        totalIn += amount;
        bucket['in'] = currentIn + amount;
      } else {
        totalOut += amount;
        bucket['out'] = currentOut + amount;
      }
      bucket['balance'] = _toDouble(bucket['in']) - _toDouble(bucket['out']);
      byFund[fund] = bucket;
    }

    summary['byFund'] = byFund;
    summary['totalIn'] = totalIn;
    summary['totalOut'] = totalOut;
    summary['balance'] = totalIn - totalOut;
    summary['totalFound'] = totalIn;
    final zakatIn = _toDouble(
        (Map<String, dynamic>.from(byFund['JAKAT'] as Map? ?? {}))['in']);
    final scholarshipIn = _toDouble((Map<String, dynamic>.from(
        byFund['SCHOLARSHIP'] as Map? ?? {}))['in']);
    summary['balanceExclZakat'] = totalIn - zakatIn;
    summary['balanceExclZakatScholarship'] =
        _toDouble(summary['balanceExclZakat']) - scholarshipIn;
    return summary;
  }

  Map<String, dynamic> _overlayMonthlyReport(
    Map<String, dynamic> body,
    dynamic data,
    List<Map<String, dynamic>> queue,
  ) {
    final report = Map<String, dynamic>.from(data as Map? ?? {});
    final monthKey = _string(body['monthKey']);
    final rows = (report['rows'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final pending = queue
        .map(_pendingTransactionFromQueuedAction)
        .whereType<Map<String, dynamic>>()
        .where((txn) => _string(txn['txn_date']).startsWith(monthKey))
        .toList();
    final merged = _mergeRows(rows, pending, sortByDateField: 'txn_date');
    var totalIn = _toDouble(report['totalIn']);
    var totalOut = _toDouble(report['totalOut']);
    for (final txn in pending) {
      final amount = _toDouble(txn['amount']);
      if (_string(txn['direction']).toUpperCase() == 'IN') {
        totalIn += amount;
      } else {
        totalOut += amount;
      }
    }
    report['rows'] = merged;
    report['totalIn'] = totalIn;
    report['totalOut'] = totalOut;
    report['balance'] = totalIn - totalOut;
    return report;
  }

  Map<String, dynamic> _overlayRangeReport(
    Map<String, dynamic> body,
    dynamic data,
    List<Map<String, dynamic>> queue,
  ) {
    final report = Map<String, dynamic>.from(data as Map? ?? {});
    final from = _string(body['from']);
    final to = _string(body['to']);
    final rows = (report['rows'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final byFund = Map<String, dynamic>.from(report['byFund'] as Map? ?? {});
    final byMonth = Map<String, dynamic>.from(report['byMonth'] as Map? ?? {});
    final pending = queue
        .map(_pendingTransactionFromQueuedAction)
        .whereType<Map<String, dynamic>>()
        .where((txn) => _inDateRange(_string(txn['txn_date']), from, to))
        .toList();

    var totalIn = _toDouble(report['totalIn']);
    var totalOut = _toDouble(report['totalOut']);

    for (final txn in pending) {
      final fund = _string(txn['fund_type']).toUpperCase();
      final dir = _string(txn['direction']).toUpperCase();
      final amount = _toDouble(txn['amount']);
      final monthKey = _string(txn['txn_date']).substring(0, 7);

      final fundBucket = Map<String, dynamic>.from(byFund[fund] as Map? ?? {});
      final monthBucket =
          Map<String, dynamic>.from(byMonth[monthKey] as Map? ?? {});

      if (dir == 'IN') {
        totalIn += amount;
        fundBucket['in'] = _toDouble(fundBucket['in']) + amount;
        monthBucket['in'] = _toDouble(monthBucket['in']) + amount;
      } else {
        totalOut += amount;
        fundBucket['out'] = _toDouble(fundBucket['out']) + amount;
        monthBucket['out'] = _toDouble(monthBucket['out']) + amount;
      }

      fundBucket['balance'] =
          _toDouble(fundBucket['in']) - _toDouble(fundBucket['out']);
      monthBucket['balance'] =
          _toDouble(monthBucket['in']) - _toDouble(monthBucket['out']);
      byFund[fund] = fundBucket;
      byMonth[monthKey] = monthBucket;
    }

    report['rows'] = _mergeRows(rows, pending, sortByDateField: 'txn_date');
    report['byFund'] = byFund;
    report['byMonth'] = byMonth;
    report['totalIn'] = totalIn;
    report['totalOut'] = totalOut;
    report['balance'] = totalIn - totalOut;
    return report;
  }

  Map<String, dynamic> _overlayDatasetStats(
    dynamic data,
    List<Map<String, dynamic>> queue,
  ) {
    final stats = Map<String, dynamic>.from(data as Map? ?? {});
    final pending = queue
        .map(_pendingTransactionFromQueuedAction)
        .whereType<Map<String, dynamic>>()
        .toList();
    if (pending.isEmpty) return stats;

    var totalRows = (stats['txns_total_rows'] as num? ?? 0).toInt();
    var activeRows = (stats['txns_active_rows'] as num? ?? 0).toInt();
    var totalIn = _toDouble(stats['total_in']);
    var totalOut = _toDouble(stats['total_out']);
    var firstDate = _string(stats['first_txn_date']);
    var lastDate = _string(stats['last_txn_date']);

    for (final txn in pending) {
      totalRows++;
      activeRows++;
      final date = _string(txn['txn_date']);
      if (firstDate.isEmpty || date.compareTo(firstDate) < 0) firstDate = date;
      if (lastDate.isEmpty || date.compareTo(lastDate) > 0) lastDate = date;
      final amount = _toDouble(txn['amount']);
      if (_string(txn['direction']).toUpperCase() == 'IN') {
        totalIn += amount;
      } else {
        totalOut += amount;
      }
    }

    stats['txns_total_rows'] = totalRows;
    stats['txns_active_rows'] = activeRows;
    stats['first_txn_date'] = firstDate;
    stats['last_txn_date'] = lastDate;
    stats['total_in'] = totalIn;
    stats['total_out'] = totalOut;
    stats['balance'] = totalIn - totalOut;
    return stats;
  }

  List<Map<String, dynamic>> _overlaySimpleList(
    dynamic data,
    List<Map<String, dynamic>> queue, {
    required String targetAction,
    required Map<String, dynamic>? Function(Map<String, dynamic>) mapItem,
    bool Function(Map<String, dynamic>)? filter,
  }) {
    final rows = (data as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final pending = queue
        .where((item) => _string(item['action']) == targetAction)
        .map(mapItem)
        .whereType<Map<String, dynamic>>()
        .where((item) => filter == null || filter(item))
        .toList();
    return _mergeRows(rows, pending);
  }

  List<Map<String, dynamic>> _mergeRows(
    List<Map<String, dynamic>> existing,
    List<Map<String, dynamic>> pending, {
    String? sortByDateField,
  }) {
    final merged = <Map<String, dynamic>>[
      ...existing.map((row) => Map<String, dynamic>.from(row)),
    ];
    for (final item in pending) {
      final id = _string(item['id']);
      final index = id.isEmpty
          ? -1
          : merged.indexWhere((row) => _string(row['id']) == id);
      if (index >= 0) {
        merged[index] = {...merged[index], ...item};
      } else {
        merged.insert(0, item);
      }
    }
    if (sortByDateField != null) {
      merged.sort((a, b) =>
          _string(b[sortByDateField]).compareTo(_string(a[sortByDateField])));
    }
    return merged;
  }

  Map<String, dynamic>? _pendingTransactionFromQueuedAction(
      Map<String, dynamic> item) {
    final action = _string(item['action']);
    final body = Map<String, dynamic>.from(item['payload'] as Map? ?? {});
    final payload = Map<String, dynamic>.from(body['payload'] as Map? ?? {});
    final queuedAt = _string(item['queued_at']);

    if (action == 'createTransaction') {
      return {
        'id': 'pending_txn_$queuedAt',
        'txn_date': _string(payload['txn_date']),
        'direction': _string(payload['direction']).toUpperCase(),
        'fund_type': _string(payload['fund_type']).toUpperCase(),
        'amount': _toDouble(payload['amount']),
        'source_or_vendor': _string(payload['source_or_vendor']),
        'category': _string(payload['category']),
        'reference': _string(payload['reference']),
        'notes': _string(payload['notes']),
        'status': 'PENDING_SYNC',
        'created_by': _string(payload['created_by']),
      };
    }

    if (action == 'recordSalaryPayment') {
      final monthKey = _string(payload['month_key']);
      return {
        'id': 'pending_txn_salary_$queuedAt',
        'txn_date': monthKey.isNotEmpty ? '$monthKey-01' : '',
        'direction': 'OUT',
        'fund_type': _string(payload['fund_type']).toUpperCase(),
        'amount': _toDouble(payload['paid_amount']),
        'source_or_vendor': _string(payload['staff_name']).isEmpty
            ? 'Salary Payment'
            : _string(payload['staff_name']),
        'category': 'SALARY',
        'reference': '',
        'notes': 'pending salary sync',
        'status': 'PENDING_SYNC',
        'created_by': _string(payload['created_by']),
      };
    }

    if (action == 'saveScholarshipPayment') {
      final monthKey = _string(payload['month_key']);
      return {
        'id': 'pending_txn_scholarship_$queuedAt',
        'txn_date': monthKey.isNotEmpty ? '$monthKey-01' : '',
        'direction': 'OUT',
        'fund_type': _string(payload['fund_type']).toUpperCase(),
        'amount': _toDouble(payload['total_paid']),
        'source_or_vendor': _string(payload['beneficiary_name']).isEmpty
            ? 'Scholarship Payment'
            : _string(payload['beneficiary_name']),
        'category': 'SCHOLARSHIP_PAYMENT',
        'reference': '',
        'notes': 'pending scholarship sync',
        'status': 'PENDING_SYNC',
        'created_by': _string(payload['created_by']),
      };
    }

    return null;
  }

  Map<String, dynamic>? _pendingBeneficiary(Map<String, dynamic> item) {
    final payload =
        Map<String, dynamic>.from((item['payload'] as Map?)?['payload'] as Map? ?? {});
    if (_string(payload['name_bn']).isEmpty) return null;
    return {
      ...payload,
      'id': _string(payload['id']).isEmpty
          ? 'pending_ben_${_string(item['queued_at'])}'
          : _string(payload['id']),
      'status': 'PENDING_SYNC',
    };
  }

  Map<String, dynamic>? _pendingStaff(Map<String, dynamic> item) {
    final payload =
        Map<String, dynamic>.from((item['payload'] as Map?)?['payload'] as Map? ?? {});
    if (_string(payload['staff_name']).isEmpty) return null;
    return {
      ...payload,
      'id': _string(payload['id']).isEmpty
          ? 'pending_staff_${_string(item['queued_at'])}'
          : _string(payload['id']),
      'status': 'PENDING_SYNC',
    };
  }

  Map<String, dynamic>? _pendingSalaryPayment(Map<String, dynamic> item) {
    final payload =
        Map<String, dynamic>.from((item['payload'] as Map?)?['payload'] as Map? ?? {});
    if (_string(payload['staff_id']).isEmpty) return null;
    return {
      ...payload,
      'id': 'pending_salary_${_string(item['queued_at'])}',
      'payment_date': _string(payload['month_key']).isNotEmpty
          ? '${_string(payload['month_key'])}-01'
          : '',
      'status': _string(payload['status']).isEmpty
          ? 'PENDING_SYNC'
          : _string(payload['status']),
    };
  }

  Map<String, dynamic>? _pendingScholarshipPayment(Map<String, dynamic> item) {
    final payload =
        Map<String, dynamic>.from((item['payload'] as Map?)?['payload'] as Map? ?? {});
    if (_string(payload['beneficiary_id']).isEmpty) return null;
    return {
      ...payload,
      'id': 'pending_scholarship_${_string(item['queued_at'])}',
      'payment_date': _string(payload['month_key']).isNotEmpty
          ? '${_string(payload['month_key'])}-01'
          : '',
      'status': 'PENDING_SYNC',
    };
  }

  Map<String, dynamic>? _pendingStudent(Map<String, dynamic> item) {
    final payload =
        Map<String, dynamic>.from((item['payload'] as Map?)?['payload'] as Map? ?? {});
    if (_string(payload['name_bn']).isEmpty) return null;
    return {
      ...payload,
      'id': _string(payload['id']).isEmpty
          ? 'pending_student_${_string(item['queued_at'])}'
          : _string(payload['id']),
      'status': _string(payload['status']).isEmpty
          ? 'ACTIVE'
          : _string(payload['status']),
    };
  }

  Map<String, dynamic>? _pendingGuardian(Map<String, dynamic> item) {
    final payload =
        Map<String, dynamic>.from((item['payload'] as Map?)?['payload'] as Map? ?? {});
    if (_string(payload['student_id']).isEmpty || _string(payload['name']).isEmpty) {
      return null;
    }
    return {
      ...payload,
      'id': _string(payload['id']).isEmpty
          ? 'pending_guardian_${_string(item['queued_at'])}'
          : _string(payload['id']),
      'status': _string(payload['status']).isEmpty
          ? 'ACTIVE'
          : _string(payload['status']),
    };
  }

  Map<String, dynamic>? _pendingClass(Map<String, dynamic> item) {
    final payload =
        Map<String, dynamic>.from((item['payload'] as Map?)?['payload'] as Map? ?? {});
    if (_string(payload['name']).isEmpty) return null;
    return {
      ...payload,
      'id': _string(payload['id']).isEmpty
          ? 'pending_class_${_string(item['queued_at'])}'
          : _string(payload['id']),
      'status': _string(payload['status']).isEmpty
          ? 'ACTIVE'
          : _string(payload['status']),
    };
  }

  Map<String, dynamic>? _pendingSection(Map<String, dynamic> item) {
    final payload =
        Map<String, dynamic>.from((item['payload'] as Map?)?['payload'] as Map? ?? {});
    if (_string(payload['class_id']).isEmpty || _string(payload['name']).isEmpty) {
      return null;
    }
    return {
      ...payload,
      'id': _string(payload['id']).isEmpty
          ? 'pending_section_${_string(item['queued_at'])}'
          : _string(payload['id']),
      'status': _string(payload['status']).isEmpty
          ? 'ACTIVE'
          : _string(payload['status']),
    };
  }

  Map<String, dynamic>? _pendingSubject(Map<String, dynamic> item) {
    final payload =
        Map<String, dynamic>.from((item['payload'] as Map?)?['payload'] as Map? ?? {});
    if (_string(payload['class_id']).isEmpty || _string(payload['name']).isEmpty) {
      return null;
    }
    return {
      ...payload,
      'id': _string(payload['id']).isEmpty
          ? 'pending_subject_${_string(item['queued_at'])}'
          : _string(payload['id']),
      'status': _string(payload['status']).isEmpty
          ? 'ACTIVE'
          : _string(payload['status']),
    };
  }

  Map<String, dynamic>? _pendingFeePlan(Map<String, dynamic> item) {
    final payload =
        Map<String, dynamic>.from((item['payload'] as Map?)?['payload'] as Map? ?? {});
    if (_string(payload['name']).isEmpty) return null;
    return {
      ...payload,
      'id': _string(payload['id']).isEmpty
          ? 'pending_fee_plan_${_string(item['queued_at'])}'
          : _string(payload['id']),
      'status': _string(payload['status']).isEmpty
          ? 'ACTIVE'
          : _string(payload['status']),
    };
  }

  bool _matchesTransactionQuery(
      Map<String, dynamic> txn, Map<String, dynamic> query) {
    final direction = _string(query['direction']).toUpperCase();
    final fundType = _string(query['fundType']).toUpperCase();
    final from = _string(query['from']);
    final to = _string(query['to']);
    final txnDirection = _string(txn['direction']).toUpperCase();
    final txnFund = _string(txn['fund_type']).toUpperCase();
    final txnDate = _string(txn['txn_date']);
    if (direction.isNotEmpty && txnDirection != direction) return false;
    if (fundType.isNotEmpty && txnFund != fundType) return false;
    if (!_inDateRange(txnDate, from, to)) return false;
    return true;
  }

  bool _inDateRange(String txnDate, String from, String to) {
    if (txnDate.isEmpty) return false;
    if (from.isNotEmpty && txnDate.compareTo(from) < 0) return false;
    if (to.isNotEmpty && txnDate.compareTo(to) > 0) return false;
    return true;
  }

  bool _matchesOptional(dynamic actual, dynamic expected) {
    final expectedText = _string(expected);
    if (expectedText.isEmpty) return true;
    return _string(actual) == expectedText;
  }

  String _string(dynamic value) => (value ?? '').toString().trim();

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    final cleaned = _string(value).replaceAll(',', '').replaceAll('৳', '');
    return double.tryParse(cleaned) ?? 0;
  }
}
