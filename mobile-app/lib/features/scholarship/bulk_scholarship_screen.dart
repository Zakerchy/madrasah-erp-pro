import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../shared/constants/app_permissions.dart';
import '../../shared/models/dashboard_summary.dart';
import '../../shared/services/access_control_service.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';

class _BeneficiaryRow {
  final String id;
  final String nameBn;
  final double monthlyNeed;
  final TextEditingController amount;
  bool skip = false;
  String status = 'PAID';

  _BeneficiaryRow({
    required this.id,
    required this.nameBn,
    required this.monthlyNeed,
    double initialAmount = 0,
  }) : amount = TextEditingController(
            text: initialAmount > 0 ? initialAmount.toInt().toString() : '0');

  void dispose() => amount.dispose();
}

class BulkScholarshipScreen extends StatefulWidget {
  const BulkScholarshipScreen({super.key});

  @override
  State<BulkScholarshipScreen> createState() => _BulkScholarshipScreenState();
}

class _BulkScholarshipScreenState extends State<BulkScholarshipScreen> {
  final _api = ApiService();
  bool _loading = true;
  bool _saving = false;

  final _now = DateTime.now();
  late String _monthKey;
  late final TextEditingController _monthCtrl;

  List<_BeneficiaryRow> _rows = [];
  String _fundType = 'SCHOLARSHIP';

  bool get _canWrite => SessionService.can(AppPermissions.scholarshipWrite);

  @override
  void initState() {
    super.initState();
    _monthKey =
        '${_now.year}-${_now.month.toString().padLeft(2, '0')}';
    _monthCtrl = TextEditingController(text: _monthKey);
    _loadBeneficiaries();
  }

  @override
  void dispose() {
    _monthCtrl.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _loadBeneficiaries({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('listBeneficiaries',
          forceRefresh: forceRefresh);
      if (res['ok'] == true) {
        final list = (res['data'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        for (final r in _rows) {
          r.dispose();
        }
        _rows = list.map((b) {
          return _BeneficiaryRow(
            id: b['id'].toString(),
            nameBn: b['name_bn']?.toString() ?? '',
            monthlyNeed:
                double.tryParse(b['monthly_need_amount']?.toString() ?? '0') ??
                    0,
            initialAmount:
                double.tryParse(b['monthly_need_amount']?.toString() ?? '0') ??
                    0,
          );
        }).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  /// গত মাসের payment থেকে amount pre-fill করে
  Future<void> _autoFillFromLastMonth() async {
    final parts = _monthKey.split('-');
    if (parts.length != 2) return;
    final year = int.tryParse(parts[0]) ?? _now.year;
    final month = int.tryParse(parts[1]) ?? _now.month;

    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final prevKey =
        '$prevYear-${prevMonth.toString().padLeft(2, '0')}';

    setState(() => _loading = true);
    try {
      final res = await _api.get('listScholarshipByMonth',
          query: {'monthKey': prevKey}, forceRefresh: true);
      if (res['ok'] == true) {
        final payments = (res['data'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        final amountByBeneficiary = <String, double>{};
        final statusByBeneficiary = <String, String>{};
        for (final p in payments) {
          final bid = p['beneficiary_id']?.toString() ?? '';
          if (bid.isNotEmpty) {
            amountByBeneficiary[bid] =
                double.tryParse(p['total_paid']?.toString() ?? '0') ?? 0;
            statusByBeneficiary[bid] =
                p['payment_status']?.toString() ?? 'PAID';
          }
        }

        setState(() {
          for (final row in _rows) {
            if (amountByBeneficiary.containsKey(row.id)) {
              final amt = amountByBeneficiary[row.id]!;
              row.amount.text =
                  amt > 0 ? amt.toInt().toString() : '0';
              row.status = statusByBeneficiary[row.id] ?? 'PAID';
              row.skip = false;
            }
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLang.t(
                  '$prevKey-এর ডেটা থেকে auto-fill হয়েছে',
                  'Auto-filled from $prevKey'))));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveAll() async {
    if (!_canWrite) {
      AccessControlService.showDeniedSnack(
        context,
        permission: AppPermissions.scholarshipWrite,
        routeName: '/scholarship',
      );
      return;
    }
    if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(_monthKey.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              AppLang.t('মাসের ফরম্যাট YYYY-MM দিন', 'Use format YYYY-MM'))));
      return;
    }

    final toSave = _rows.where((r) => !r.skip).toList();
    if (toSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLang.t(
              'কোনো সুবিধাভোগী নির্বাচিত নেই', 'No beneficiaries selected'))));
      return;
    }

    final invalidRows =
        toSave.where((r) => (double.tryParse(r.amount.text) ?? 0) <= 0);
    if (invalidRows.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLang.t(
              '${invalidRows.map((r) => r.nameBn).join(", ")}-এর পরিমাণ ০ এর বেশি হতে হবে',
              'Amount must be > 0 for: ${invalidRows.map((r) => r.nameBn).join(", ")}'))));
      return;
    }

    // Fund balance check
    try {
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final totalNeeded = toSave.fold<double>(
          0, (s, r) => s + (double.tryParse(r.amount.text) ?? 0));
      final balRes = await _api
          .get('dashboardSummary', query: {'from': '2022-01-26', 'to': today});
      if (balRes['ok'] == true) {
        final summary = DashboardSummary.fromMap(
            Map<String, dynamic>.from(balRes['data'] as Map? ?? {}));
        final balance = summary.fund(_fundType).balance;
        if (balance < totalNeeded) {
          if (!mounted) return;
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(AppLang.t('ফান্ড অপর্যাপ্ত', 'Insufficient Fund')),
              content: Text(AppLang.t(
                '$_fundType ব্যালেন্স ৳${balance.toInt()}, মোট পরিশোধ ৳${totalNeeded.toInt()}। তবুও সংরক্ষণ করবেন?',
                '$_fundType balance ৳${balance.toInt()}, total payment ৳${totalNeeded.toInt()}. Save anyway?',
              )),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(AppLang.t('বাতিল', 'Cancel'))),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(AppLang.t('হ্যাঁ, সংরক্ষণ', 'Yes, Save'))),
              ],
            ),
          );
          if (!mounted || proceed != true) return;
        }
      }
    } catch (_) {}

    setState(() => _saving = true);
    int saved = 0;
    int failed = 0;

    for (final row in toSave) {
      if (!mounted) break;
      final total = double.tryParse(row.amount.text) ?? 0;
      final remaining = (row.monthlyNeed - total).clamp(0.0, double.infinity);
      final res = await _api.post('saveScholarshipPayment', {
        'user_role': SessionService.role,
        'payload': {
          'month_key': _monthKey,
          'beneficiary_id': row.id,
          'beneficiary_name': row.nameBn,
          'school_fee': 0,
          'bangla_tutor': 0,
          'arabi_tutor': 0,
          'materials': 0,
          'other': 0,
          'total_paid': total,
          'remaining_amount': remaining,
          'payment_status': row.status,
          'fund_type': _fundType,
          'created_by': SessionService.userId,
        }
      });
      if (res['ok'] == true) {
        saved++;
      } else {
        failed++;
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);

    final msg = failed == 0
        ? AppLang.t('$saved জন সুবিধাভোগীর পরিশোধ সংরক্ষিত',
            '$saved payments saved successfully')
        : AppLang.t('$saved সংরক্ষিত, $failed ব্যর্থ',
            '$saved saved, $failed failed');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));

    if (failed == 0 && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _rows
        .where((r) => !r.skip)
        .fold<double>(0, (s, r) => s + (double.tryParse(r.amount.text) ?? 0));

    return ValueListenableBuilder<bool>(
      valueListenable: AppLang.isEnglish,
      builder: (context, _, __) => BaseScaffold(
        title: AppLang.t('বাল্ক বৃত্তি প্রদান', 'Bulk Scholarship Entry'),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Header controls
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _monthCtrl,
                                decoration: InputDecoration(
                                    labelText: AppLang.t(
                                        'মাস (YYYY-MM)', 'Month (YYYY-MM)')),
                                onChanged: (v) =>
                                    setState(() => _monthKey = v.trim()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _fundType,
                              items: const [
                                DropdownMenuItem(
                                    value: 'SCHOLARSHIP',
                                    child: Text('SCHOLARSHIP')),
                                DropdownMenuItem(
                                    value: 'JAKAT', child: Text('JAKAT')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _fundType = v ?? 'SCHOLARSHIP'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _autoFillFromLastMonth,
                          icon: const Icon(Icons.auto_fix_high, size: 18),
                          label: Text(AppLang.t(
                              'গত মাস থেকে auto-fill',
                              'Auto-fill from last month')),
                        ),
                        const SizedBox(height: 8),
                        // Total summary bar
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(
                                AppLang.t(
                                    '${_rows.where((r) => !r.skip).length} জন • মোট',
                                    '${_rows.where((r) => !r.skip).length} selected • Total'),
                                style: const TextStyle(fontSize: 13),
                              ),
                              const Spacer(),
                              Text(
                                '৳${total.toInt()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  // Beneficiary list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                      itemCount: _rows.length,
                      itemBuilder: (ctx, i) {
                        final row = _rows[i];
                        return _BeneficiaryTile(
                          row: row,
                          onChanged: () => setState(() {}),
                        );
                      },
                    ),
                  ),
                ],
              ),
        floatingActionButton: _saving
            ? const FloatingActionButton(
                onPressed: null,
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : FloatingActionButton.extended(
                onPressed: _saveAll,
                icon: const Icon(Icons.save_alt),
                label: Text(AppLang.t('সব সংরক্ষণ', 'Save All')),
              ),
      ),
    );
  }
}

class _BeneficiaryTile extends StatefulWidget {
  final _BeneficiaryRow row;
  final VoidCallback onChanged;

  const _BeneficiaryTile({required this.row, required this.onChanged});

  @override
  State<_BeneficiaryTile> createState() => _BeneficiaryTileState();
}

class _BeneficiaryTileState extends State<_BeneficiaryTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = widget.row;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            // Skip checkbox
            Checkbox(
              value: !row.skip,
              onChanged: (v) {
                setState(() => row.skip = !(v ?? true));
                widget.onChanged();
              },
            ),
            const SizedBox(width: 4),
            // Name + monthly need
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.nameBn,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: row.skip
                              ? theme.disabledColor
                              : null)),
                  if (row.monthlyNeed > 0)
                    Text(
                      AppLang.t(
                          'মাসিক প্রয়োজন: ৳${row.monthlyNeed.toInt()}',
                          'Monthly need: ৳${row.monthlyNeed.toInt()}'),
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.outline),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount field
            SizedBox(
              width: 90,
              child: TextField(
                controller: row.amount,
                enabled: !row.skip,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  prefixText: '৳',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                ),
                onChanged: (_) => widget.onChanged(),
              ),
            ),
            const SizedBox(width: 6),
            // Status dropdown (compact)
            DropdownButton<String>(
              value: row.status,
              isDense: true,
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(
                    value: 'PAID',
                    child: Text(AppLang.t('পরিশোধিত', 'PAID'),
                        style: const TextStyle(fontSize: 12))),
                DropdownMenuItem(
                    value: 'PARTIAL',
                    child: Text(AppLang.t('আংশিক', 'PARTIAL'),
                        style: const TextStyle(fontSize: 12))),
              ],
              onChanged: row.skip
                  ? null
                  : (v) => setState(() => row.status = v ?? 'PAID'),
            ),
          ],
        ),
      ),
    );
  }
}
