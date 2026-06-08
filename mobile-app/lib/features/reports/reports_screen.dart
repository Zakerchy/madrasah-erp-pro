import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_lang.dart';
import '../../shared/models/app_ui_settings.dart';
import '../../shared/services/api_service.dart';
import '../../shared/widgets/base_scaffold.dart';
import '../../shared/widgets/themed_date_picker.dart';

enum _ReportViewMode { monthly, range, yearly }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _api = ApiService();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _data;
  AppUiSettings _uiSettings = AppUiSettings.defaults();
  _ReportViewMode _mode = _ReportViewMode.monthly;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _rangeFrom = DateTime(2022, 1, 26);
  DateTime _rangeTo = DateTime.now();
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadDefaults();
    await _loadReport();
  }

  String _fmtDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  String _monthKey(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}';
  }

  Future<void> _loadDefaults() async {
    try {
      final res = await _api.get('getAppUiSettings');
      if (res['ok'] == true) {
        final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
        final settings = AppUiSettings.fromApi(data);
        final to = settings.defaultToDate;
        final from = settings.defaultFromDate.isAfter(to)
            ? to
            : settings.defaultFromDate;
        setState(() {
          _uiSettings = settings;
          _rangeFrom = from;
          _rangeTo = to;
          _selectedMonth = DateTime(to.year, to.month);
          _selectedYear = to.year;
        });
      }
    } catch (_) {
      // Keep local defaults silently.
    }
  }

  int _rangeDaysInclusive(DateTime from, DateTime to) {
    return to.difference(from).inDays + 1;
  }

  bool _validateRange(DateTime from, DateTime to) {
    final days = _rangeDaysInclusive(from, to);
    if (days <= _uiSettings.maxRangeDays) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLang.t(
            'সর্বোচ্চ ১ বছরের (${_uiSettings.maxRangeDays} দিন) রিপোর্ট দেখা যাবে',
            'Maximum 1 year (${_uiSettings.maxRangeDays} days) is allowed',
          ),
        ),
        backgroundColor: Colors.red.shade700,
      ),
    );
    return false;
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_mode == _ReportViewMode.monthly) {
        final monthKey = _monthKey(_selectedMonth);
        final res =
            await _api.get('monthlyReport', query: {'monthKey': monthKey});
        if (res['ok'] == true) {
          final data = Map<String, dynamic>.from((res['data'] ?? {}) as Map);
          data['reportType'] = 'monthly';
          data['label'] = monthKey;
          _data = data;
        } else {
          _error =
              (res['message'] ?? res['error'] ?? AppLang.t('ব্যর্থ', 'Failed'))
                  .toString();
        }
      } else if (_mode == _ReportViewMode.range) {
        if (!_validateRange(_rangeFrom, _rangeTo)) {
          setState(() => _loading = false);
          return;
        }
        final from = _fmtDate(_rangeFrom);
        final to = _fmtDate(_rangeTo);
        final res =
            await _api.get('rangeReport', query: {'from': from, 'to': to});
        if (res['ok'] == true) {
          final data = Map<String, dynamic>.from((res['data'] ?? {}) as Map);
          data['reportType'] = 'range';
          data['label'] = '$from → $to';
          _data = data;
        } else {
          _error =
              (res['message'] ?? res['error'] ?? AppLang.t('ব্যর্থ', 'Failed'))
                  .toString();
        }
      } else {
        final now = DateTime.now();
        final start = DateTime(_selectedYear, 1, 1);
        final fullEnd = DateTime(_selectedYear, 12, 31);
        final currentDay = DateTime(now.year, now.month, now.day);
        final end = fullEnd.isAfter(currentDay) ? currentDay : fullEnd;
        if (!_validateRange(start, end)) {
          setState(() => _loading = false);
          return;
        }

        final from = _fmtDate(start);
        final to = _fmtDate(end);
        final res =
            await _api.get('rangeReport', query: {'from': from, 'to': to});
        if (res['ok'] == true) {
          final data = Map<String, dynamic>.from((res['data'] ?? {}) as Map);
          data['reportType'] = 'yearly';
          data['label'] = _selectedYear.toString();
          _data = data;
        } else {
          _error =
              (res['message'] ?? res['error'] ?? AppLang.t('ব্যর্থ', 'Failed'))
                  .toString();
        }
      }
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) setState(() => _loading = false);
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    final cleaned =
        (value ?? '').toString().replaceAll(',', '').replaceAll('৳', '').trim();
    return double.tryParse(cleaned) ?? 0;
  }

  String _fmt(double n) =>
      '৳${NumberFormat('#,##0.##', 'en_US').format(n)}';

  Future<void> _shareReport() async {
    if (_data == null) return;
    final label = (_data!['label'] ?? '').toString();
    final reportType = (_data!['reportType'] ?? 'range').toString();
    final title = reportType == 'monthly'
        ? 'Monthly Report'
        : reportType == 'yearly'
            ? 'Yearly Report'
            : 'Range Report';
    final totalIn = _data!['totalIn'] ?? 0;
    final totalOut = _data!['totalOut'] ?? 0;
    final balance = _data!['balance'] ?? 0;
    final rows = ((_data!['rows'] as List<dynamic>?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final sb = StringBuffer();
    sb.writeln('📊 Madrasah ERP — $title ($label)');
    sb.writeln('══════════════════════');
    sb.writeln('Total In    : ৳$totalIn');
    sb.writeln('Total Out   : ৳$totalOut');
    sb.writeln('Balance     : ৳$balance');
    if (rows.isNotEmpty) {
      sb.writeln('\nTransactions:');
      for (final r in rows.take(30)) {
        final dir = r['direction'] == 'IN' ? '↑' : '↓';
        sb.writeln(
            '$dir ৳${r['amount']}  ${r['source_or_vendor'] ?? ''}  ${r['txn_date'] ?? ''}');
      }
      if (rows.length > 30) sb.writeln('... and ${rows.length - 30} more');
    }
    await Share.share(sb.toString());
  }

  String _csvEscape(dynamic value) {
    final text = (value ?? '').toString().replaceAll('"', '""');
    return '"$text"';
  }

  Future<void> _shareCsvReport() async {
    if (_data == null) return;
    final label = (_data!['label'] ?? 'report').toString();
    final rows = ((_data!['rows'] as List<dynamic>?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final out = StringBuffer();
    out.writeln(
        'txn_date,direction,fund_type,amount,source_or_vendor,category,notes');
    for (final r in rows) {
      out.writeln([
        _csvEscape(r['txn_date']),
        _csvEscape(r['direction']),
        _csvEscape(r['fund_type']),
        _csvEscape(r['amount']),
        _csvEscape(r['source_or_vendor']),
        _csvEscape(r['category']),
        _csvEscape(r['notes']),
      ].join(','));
    }
    await Share.share(out.toString(), subject: 'Madrasah ERP CSV $label');
  }

  Future<void> _pickMonth() async {
    final picked = await showThemedDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    setState(() => _selectedMonth = DateTime(picked.year, picked.month));
  }

  Future<void> _pickYear() async {
    final picked = await showThemedDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, 1, 1),
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    setState(() => _selectedYear = picked.year);
  }

  Future<void> _pickRange() async {
    final picked = await showThemedDateRangePicker(
      context: context,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _rangeFrom, end: _rangeTo),
    );
    if (picked == null) return;
    final from =
        DateTime(picked.start.year, picked.start.month, picked.start.day);
    final to = DateTime(picked.end.year, picked.end.month, picked.end.day);
    if (!_validateRange(from, to)) return;
    setState(() {
      _rangeFrom = from;
      _rangeTo = to;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = ((_data?['rows'] as List<dynamic>?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final totalIn = _toDouble(_data?['totalIn']);
    final totalOut = _toDouble(_data?['totalOut']);
    final balance = _toDouble(_data?['balance']);

    return ValueListenableBuilder<bool>(
      valueListenable: AppLang.isEnglish,
      builder: (context, isEn, _) => BaseScaffold(
        title: AppLang.t('রিপোর্ট', 'Reports'),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLang.t('রিপোর্ট টাইপ', 'Report Type'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<_ReportViewMode>(
                      segments: [
                        ButtonSegment(
                          value: _ReportViewMode.monthly,
                          icon: const Icon(Icons.calendar_view_month),
                          label: Text(AppLang.t('মাসিক', 'Monthly')),
                        ),
                        ButtonSegment(
                          value: _ReportViewMode.range,
                          icon: const Icon(Icons.date_range),
                          label: Text(AppLang.t('রেঞ্জ', 'Range')),
                        ),
                        ButtonSegment(
                          value: _ReportViewMode.yearly,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(AppLang.t('বার্ষিক', 'Yearly')),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (next) {
                        setState(() => _mode = next.first);
                      },
                    ),
                    const SizedBox(height: 10),
                    if (_mode == _ReportViewMode.monthly)
                      OutlinedButton.icon(
                        onPressed: _pickMonth,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                            '${AppLang.t('মাস', 'Month')}: ${_monthKey(_selectedMonth)}'),
                      ),
                    if (_mode == _ReportViewMode.range)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickRange,
                            icon: const Icon(Icons.date_range),
                            label: Text(
                                '${_fmtDate(_rangeFrom)} → ${_fmtDate(_rangeTo)}'),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLang.t(
                              'সর্বোচ্চ ${_uiSettings.maxRangeDays} দিন (১ বছর)',
                              'Maximum ${_uiSettings.maxRangeDays} days (1 year)',
                            ),
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 12),
                          ),
                        ],
                      ),
                    if (_mode == _ReportViewMode.yearly)
                      OutlinedButton.icon(
                        onPressed: _pickYear,
                        icon: const Icon(Icons.event),
                        label:
                            Text('${AppLang.t('বছর', 'Year')}: $_selectedYear'),
                      ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _loading ? null : _loadReport,
                      icon: const Icon(Icons.summarize),
                      label: Text(AppLang.t('রিপোর্ট দেখুন', 'Load Report')),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Text(
                '${AppLang.t('ত্রুটি', 'Error')}: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            if (_data != null && !_loading) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.arrow_upward, color: Colors.green),
                  title: Text(AppLang.t('মোট আয়', 'Total In')),
                  trailing: Text(
                    _fmt(totalIn),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.arrow_downward, color: Colors.red),
                  title: Text(AppLang.t('মোট ব্যয়', 'Total Out')),
                  trailing: Text(
                    _fmt(totalOut),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet),
                  title: Text(AppLang.t('ব্যালেন্স', 'Balance')),
                  trailing: Text(
                    _fmt(balance),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _shareReport,
                  icon: const Icon(Icons.share),
                  label: Text(AppLang.t('হিসাব শেয়ার করুন', 'Share Report')),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: rows.isEmpty ? null : _shareCsvReport,
                  icon: const Icon(Icons.table_view),
                  label: Text(AppLang.t('CSV এক্সপোর্ট', 'Export CSV')),
                ),
              ),
              const SizedBox(height: 16),
              if (rows.isNotEmpty) ...[
                Text(
                  AppLang.t('লেনদেনের তালিকা', 'Transactions'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...rows.take(120).map(
                      (r) => Card(
                        child: ListTile(
                          leading: Icon(
                            r['direction'] == 'IN'
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: r['direction'] == 'IN'
                                ? Colors.green
                                : Colors.red,
                          ),
                          title: Text(
                              '${r['source_or_vendor'] ?? ''} • ৳${r['amount'] ?? 0}'),
                          subtitle: Text(
                              '${r['fund_type'] ?? ''} • ${r['txn_date'] ?? ''} • ${r['category'] ?? ''}'),
                        ),
                      ),
                    ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
