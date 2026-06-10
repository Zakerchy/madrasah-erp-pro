import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../shared/constants/app_permissions.dart';
import '../../shared/models/dashboard_summary.dart';
import '../../shared/services/access_control_service.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';

class ScholarshipScreen extends StatefulWidget {
  const ScholarshipScreen({super.key});

  @override
  State<ScholarshipScreen> createState() => _ScholarshipScreenState();
}

class _ScholarshipScreenState extends State<ScholarshipScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _beneficiaries = [];
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;

  String _monthKey =
      '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
  late final TextEditingController _monthCtrl;
  String _selectedBeneficiaryId = '';
  String _selectedBeneficiaryName = '';
  double _selectedBeneficiaryMonthlyNeed = 0;
  String _fundType = 'SCHOLARSHIP';

  final _school = TextEditingController(text: '0');
  final _bangla = TextEditingController(text: '0');
  final _arabi = TextEditingController(text: '0');
  final _materials = TextEditingController(text: '0');
  final _other = TextEditingController(text: '0');
  final _remaining = TextEditingController(text: '0');
  String _status = 'PAID';

  bool get _canWrite => SessionService.can(AppPermissions.scholarshipWrite);

  @override
  void initState() {
    super.initState();
    _monthCtrl = TextEditingController(text: _monthKey);
    _school.addListener(_recalc);
    _bangla.addListener(_recalc);
    _arabi.addListener(_recalc);
    _materials.addListener(_recalc);
    _other.addListener(_recalc);
    _loadAll();
  }

  @override
  void dispose() {
    _school.removeListener(_recalc);
    _bangla.removeListener(_recalc);
    _arabi.removeListener(_recalc);
    _materials.removeListener(_recalc);
    _other.removeListener(_recalc);
    _monthCtrl.dispose();
    _school.dispose();
    _bangla.dispose();
    _arabi.dispose();
    _materials.dispose();
    _other.dispose();
    _remaining.dispose();
    super.dispose();
  }

  void _recalc() {
    if (!mounted) return;
    final total =
        _n(_school) + _n(_bangla) + _n(_arabi) + _n(_materials) + _n(_other);
    final rem =
        (_selectedBeneficiaryMonthlyNeed - total).clamp(0.0, double.infinity);
    final text = rem == rem.truncateToDouble()
        ? rem.toInt().toString()
        : rem.toStringAsFixed(2);
    _remaining.text = text;
    setState(() {});
  }

  Future<void> _loadAll({bool forceRefresh = false}) async {
    setState(() => _loading = true);

    try {
      final benRes = await _api.get(
        'listBeneficiaries',
        forceRefresh: forceRefresh,
      );
      if (benRes['ok'] == true) {
        _beneficiaries = ((benRes['data'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList());
        if (_beneficiaries.isNotEmpty && _selectedBeneficiaryId.isEmpty) {
          _selectedBeneficiaryId = _beneficiaries.first['id'].toString();
          _selectedBeneficiaryName =
              _beneficiaries.first['name_bn'].toString();
          _selectedBeneficiaryMonthlyNeed = double.tryParse(
                  _beneficiaries.first['monthly_need_amount']?.toString() ??
                      '0') ??
              0;
        }
      }

      final payRes = await _api.get(
        'listScholarshipByMonth',
        query: {'monthKey': _monthKey},
        forceRefresh: forceRefresh,
      );
      if (payRes['ok'] == true) {
        _payments = ((payRes['data'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList());
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  double _n(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  Future<void> _savePayment() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!_canWrite) {
      AccessControlService.showDeniedSnack(
        context,
        permission: AppPermissions.scholarshipWrite,
        routeName: '/scholarship',
      );
      return;
    }
    if (_selectedBeneficiaryId.isEmpty || _monthKey.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(
          content: Text(AppLang.t('সুবিধাভোগী ও মাস প্রয়োজন',
              'Beneficiary and month are required'))));
      return;
    }
    if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(_monthKey.trim())) {
      messenger.showSnackBar(SnackBar(
          content: Text(AppLang.t(
              'মাসের ফরম্যাট YYYY-MM দিন', 'Use month format YYYY-MM'))));
      return;
    }

    final total =
        _n(_school) + _n(_bangla) + _n(_arabi) + _n(_materials) + _n(_other);
    if (total <= 0) {
      messenger.showSnackBar(SnackBar(
          content: Text(AppLang.t('মোট পরিমাণ ০ এর বেশি হতে হবে',
              'Total amount must be > 0'))));
      return;
    }

    if (_selectedBeneficiaryMonthlyNeed > 0 &&
        total > _selectedBeneficiaryMonthlyNeed) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLang.t(
              'অতিরিক্ত পরিশোধ সতর্কতা', 'Overpayment Warning')),
          content: Text(AppLang.t(
            'মোট পরিশোধ (৳${total.toInt()}) মাসিক প্রয়োজনীয় পরিমাণ (৳${_selectedBeneficiaryMonthlyNeed.toInt()}) এর বেশি। সংরক্ষণ করবেন?',
            'Total payment (৳${total.toInt()}) exceeds monthly need (৳${_selectedBeneficiaryMonthlyNeed.toInt()}). Save anyway?',
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLang.t('বাতিল', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLang.t('হ্যাঁ, সংরক্ষণ', 'Yes, Save')),
            ),
          ],
        ),
      );
      if (!mounted || proceed != true) return;
    }

    try {
      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final balRes = await _api.get('dashboardSummary',
          query: {'from': '2022-01-26', 'to': today});
      if (balRes['ok'] == true) {
        final summary = DashboardSummary.fromMap(
            Map<String, dynamic>.from(balRes['data'] as Map? ?? {}));
        final fundBalance = summary.fund(_fundType).balance;
        if (fundBalance < total) {
          if (!mounted) return;
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(AppLang.t('ফান্ড অপর্যাপ্ত', 'Insufficient Fund')),
              content: Text(AppLang.t(
                '$_fundType ফান্ডে বর্তমান ব্যালেন্স ৳${fundBalance.toInt()}, কিন্তু পরিশোধের পরিমাণ ৳${total.toInt()}। তবুও সংরক্ষণ করবেন?',
                '$_fundType fund balance is ৳${fundBalance.toInt()} but payment is ৳${total.toInt()}. Save anyway?',
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

    final res = await _api.post('saveScholarshipPayment', {
      'user_role': SessionService.role,
      'payload': {
        'month_key': _monthKey,
        'beneficiary_id': _selectedBeneficiaryId,
        'beneficiary_name': _selectedBeneficiaryName,
        'school_fee': _n(_school),
        'bangla_tutor': _n(_bangla),
        'arabi_tutor': _n(_arabi),
        'materials': _n(_materials),
        'other': _n(_other),
        'total_paid': total,
        'remaining_amount': _n(_remaining),
        'payment_status': _status,
        'fund_type': _fundType,
        'created_by': SessionService.userId,
      }
    });

    if (!mounted) return;
    if (res['ok'] == true) {
      _school.text = '0';
      _bangla.text = '0';
      _arabi.text = '0';
      _materials.text = '0';
      _other.text = '0';
      _recalc();
      await _loadAll();
      if (!mounted) return;
      final msg = res['queued'] == true
          ? AppLang.t('অফলাইনে সংরক্ষিত।',
              'Offline saved. Will sync automatically.')
          : AppLang.t('বৃত্তি পরিশোধ সংরক্ষিত', 'Scholarship payment saved');
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } else {
      messenger.showSnackBar(
          SnackBar(content: Text('${res['message'] ?? res['error']}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final total =
        _n(_school) + _n(_bangla) + _n(_arabi) + _n(_materials) + _n(_other);
    return ValueListenableBuilder<bool>(
      valueListenable: AppLang.isEnglish,
      builder: (context, isEn, _) => BaseScaffold(
        title: AppLang.t('বৃত্তি', 'Scholarship'),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                      AppLang.t('বৃত্তি পরিশোধ নথিভুক্ত করুন',
                          'Record Scholarship Payment'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _monthCtrl,
                    decoration: InputDecoration(
                        labelText:
                            AppLang.t('মাস (YYYY-MM)', 'Month (YYYY-MM)')),
                    onChanged: (v) => _monthKey = v.trim(),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBeneficiaryId.isEmpty
                        ? null
                        : _selectedBeneficiaryId,
                    items: _beneficiaries
                        .map((b) => DropdownMenuItem(
                              value: b['id'].toString(),
                              child: Text(b['name_bn']?.toString() ?? ''),
                            ))
                        .toList(),
                    onChanged: (v) {
                      final item = _beneficiaries.firstWhere(
                          (b) => b['id'].toString() == v,
                          orElse: () => {});
                      setState(() {
                        _selectedBeneficiaryId = v ?? '';
                        _selectedBeneficiaryName =
                            item['name_bn']?.toString() ?? '';
                        _selectedBeneficiaryMonthlyNeed = double.tryParse(
                                item['monthly_need_amount']?.toString() ??
                                    '0') ??
                            0;
                      });
                      _recalc();
                    },
                    decoration: InputDecoration(
                        labelText:
                            AppLang.t('সুবিধাভোগী', 'Beneficiary')),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _school,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText:
                              AppLang.t('বিদ্যালয় বেতন', 'School Fee'))),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _bangla,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText:
                              AppLang.t('বাংলা প্রাইভেট', 'Bangla Tutor'))),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _arabi,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText:
                              AppLang.t('আরবি প্রাইভেট', 'Arabi Tutor'))),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _materials,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText:
                              AppLang.t('শিক্ষাসামগ্রী', 'Materials'))),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _other,
                      keyboardType: TextInputType.number,
                      decoration:
                          InputDecoration(labelText: AppLang.t('অন্যান্য', 'Other'))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      children: [
                        Text(AppLang.t('মোট পরিশোধ:', 'Total Paid:'),
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text(
                          '৳${total.toInt()}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.teal.shade700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _remaining,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: AppLang.t('বাকি পরিমাণ (স্বয়ংক্রিয়)',
                          'Remaining Amount (auto)'),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    items: [
                      DropdownMenuItem(
                          value: 'PAID',
                          child: Text(AppLang.t('পরিশোধিত', 'PAID'))),
                      DropdownMenuItem(
                          value: 'PARTIAL',
                          child: Text(AppLang.t('আংশিক', 'PARTIAL'))),
                      DropdownMenuItem(
                          value: 'CANCELLED',
                          child: Text(AppLang.t('বাতিল', 'CANCELLED'))),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'PAID'),
                    decoration: InputDecoration(
                        labelText: AppLang.t('অবস্থা', 'Status')),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _fundType,
                    items: [
                      DropdownMenuItem(
                          value: 'SCHOLARSHIP',
                          child: Text(
                              AppLang.t('বৃত্তি ফান্ড', 'Scholarship Fund'))),
                      DropdownMenuItem(
                          value: 'JAKAT',
                          child:
                              Text(AppLang.t('যাকাত ফান্ড', 'Jakat Fund'))),
                      DropdownMenuItem(
                          value: 'GENERAL',
                          child: Text(
                              AppLang.t('সাধারণ ফান্ড', 'General Fund'))),
                    ],
                    onChanged: (v) =>
                        setState(() => _fundType = v ?? 'SCHOLARSHIP'),
                    decoration: InputDecoration(
                        labelText: AppLang.t('ফান্ড ধরন', 'Fund Type')),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                      onPressed: _savePayment,
                      icon: const Icon(Icons.save),
                      label: Text(
                          AppLang.t('পরিশোধ সংরক্ষণ', 'Save Payment'))),
                  const Divider(height: 28),
                  Row(
                    children: [
                      Text(
                          '${AppLang.t('পরিশোধ', 'Payments')} $_monthKey',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                          onPressed: () => _loadAll(forceRefresh: true),
                          icon: const Icon(Icons.refresh)),
                    ],
                  ),
                  ..._payments.map(
                    (p) => Card(
                      child: ListTile(
                        title: Text(
                            '${p['notes'] ?? p['beneficiary_id'] ?? ''} • ৳${p['total_paid'] ?? 0}'),
                        subtitle: Text(
                            '${p['month_key'] ?? ''} • ${p['payment_status'] ?? ''} • ${p['payment_date'] ?? ''}'),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
