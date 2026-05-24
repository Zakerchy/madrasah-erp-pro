import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_lang.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _api = ApiService();
  final _month = TextEditingController(
      text:
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}');

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _data;

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.get('monthlyReport',
          query: {
            'monthKey': _month.text.trim(),
            'user_role': SessionService.role,
            'user_id': SessionService.userId,
          });
      if (res['ok'] == true) {
        _data = Map<String, dynamic>.from((res['data'] ?? {}) as Map);
      } else {
        _error = (res['message'] ?? res['error'] ?? AppLang.t('ব্যর্থ', 'Failed')).toString();
      }
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _shareReport() async {
    if (_data == null) return;
    final month = _data!['monthKey'] ?? _month.text.trim();
    final totalIn = _data!['totalIn'] ?? 0;
    final totalOut = _data!['totalOut'] ?? 0;
    final balance = _data!['balance'] ?? 0;
    final rows = ((_data!['rows'] as List<dynamic>?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final sb = StringBuffer();
    if (AppLang.isEnglish.value) {
      sb.writeln('📊 Madrasah ERP — Monthly Report ($month)');
      sb.writeln('══════════════════════');
      sb.writeln('Total In    : ৳$totalIn');
      sb.writeln('Total Out   : ৳$totalOut');
      sb.writeln('Balance     : ৳$balance');
      if (rows.isNotEmpty) {
        sb.writeln('\nTransactions:');
        for (final r in rows.take(30)) {
          final dir = r['direction'] == 'IN' ? '↑' : '↓';
          sb.writeln('$dir ৳${r['amount']}  ${r['source_or_vendor'] ?? ''}  ${r['txn_date'] ?? ''}');
        }
        if (rows.length > 30) sb.writeln('... and ${rows.length - 30} more');
      }
    } else {
      sb.writeln('📊 মাদ্রাসা ERP — মাসিক হিসাব ($month)');
      sb.writeln('══════════════════════');
      sb.writeln('মোট আয়   : ৳$totalIn');
      sb.writeln('মোট ব্যয়  : ৳$totalOut');
      sb.writeln('ব্যালেন্স  : ৳$balance');
      if (rows.isNotEmpty) {
        sb.writeln('\nলেনদেন:');
        for (final r in rows.take(30)) {
          final dir = r['direction'] == 'IN' ? '↑' : '↓';
          sb.writeln('$dir ৳${r['amount']}  ${r['source_or_vendor'] ?? ''}  ${r['txn_date'] ?? ''}');
        }
        if (rows.length > 30) sb.writeln('... আরও ${rows.length - 30} টি');
      }
    }

    await Share.share(sb.toString());
  }

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    final rows = ((_data?['rows'] as List<dynamic>?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return ValueListenableBuilder<bool>(
      valueListenable: AppLang.isEnglish,
      builder: (context, isEn, _) => BaseScaffold(
        title: AppLang.t('রিপোর্ট', 'Reports'),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _month,
              decoration: InputDecoration(
                labelText: AppLang.t('মাস (YYYY-MM)', 'Month (YYYY-MM)'),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _loading ? null : _loadReport,
              icon: const Icon(Icons.summarize),
              label: Text(AppLang.t('মাসিক রিপোর্ট দেখুন', 'Load Monthly Report')),
            ),
            const SizedBox(height: 16),
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
                    '৳${_data!['totalIn'] ?? 0}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.arrow_downward, color: Colors.red),
                  title: Text(AppLang.t('মোট ব্যয়', 'Total Out')),
                  trailing: Text(
                    '৳${_data!['totalOut'] ?? 0}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet),
                  title: Text(AppLang.t('ব্যালেন্স', 'Balance')),
                  trailing: Text(
                    '৳${_data!['balance'] ?? 0}',
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
              const SizedBox(height: 16),
              if (rows.isNotEmpty) ...[
                Text(
                  AppLang.t('লেনদেনের তালিকা', 'Transactions'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...rows.take(100).map((r) => Card(
                      child: ListTile(
                        leading: Icon(
                          r['direction'] == 'IN' ? Icons.arrow_upward : Icons.arrow_downward,
                          color: r['direction'] == 'IN' ? Colors.green : Colors.red,
                        ),
                        title: Text('${r['source_or_vendor'] ?? ''} • ৳${r['amount'] ?? 0}'),
                        subtitle: Text('${r['fund_type'] ?? ''} • ${r['txn_date'] ?? ''} • ${r['category'] ?? ''}'),
                      ),
                    )),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
