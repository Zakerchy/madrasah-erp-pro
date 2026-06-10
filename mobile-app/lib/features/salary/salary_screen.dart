import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_lang.dart';
import '../../shared/constants/app_permissions.dart';
import '../../shared/services/access_control_service.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  final _api = ApiService();

  List<Map<String, dynamic>> _staff = [];
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;

  final _staffName = TextEditingController();
  final _staffRole = TextEditingController();
  final _staffSalary = TextEditingController();

  String _selectedStaffId = '';
  final _monthKey = TextEditingController(
      text:
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}');
  final _paidAmount = TextEditingController();
  final _payableAmount = TextEditingController();
  final _dueAmount = TextEditingController(text: '0');
  String _fundType = 'GENERAL';

  bool get _canWrite => SessionService.can(AppPermissions.salaryWrite);

  @override
  void initState() {
    super.initState();
    _payableAmount.addListener(_updateDue);
    _paidAmount.addListener(_updateDue);
    _loadAll();
  }

  @override
  void dispose() {
    _payableAmount.removeListener(_updateDue);
    _paidAmount.removeListener(_updateDue);
    _staffName.dispose();
    _staffRole.dispose();
    _staffSalary.dispose();
    _monthKey.dispose();
    _paidAmount.dispose();
    _payableAmount.dispose();
    _dueAmount.dispose();
    super.dispose();
  }

  void _updateDue() {
    if (!mounted) return;
    final payable = double.tryParse(_payableAmount.text.trim()) ?? 0;
    final paid = double.tryParse(_paidAmount.text.trim()) ?? 0;
    final due = (payable - paid).clamp(0.0, double.infinity);
    final text = due == due.truncateToDouble()
        ? due.toInt().toString()
        : due.toStringAsFixed(2);
    if (_dueAmount.text != text) {
      _dueAmount.text = text;
    }
  }

  bool _isValidMonthKey(String value) {
    return RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(value.trim());
  }

  Future<void> _reloadByMonth({bool forceRefresh = false}) async {
    final month = _monthKey.text.trim();
    if (!_isValidMonthKey(month)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLang.t(
                'মাসের ফরম্যাট YYYY-MM দিন', 'Use month format YYYY-MM'))),
      );
      return;
    }
    await _loadAll(forceRefresh: forceRefresh);
  }

  Future<void> _loadAll({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    try {
      final staffRes = await _api.get('listStaff', forceRefresh: forceRefresh);
      final month = _monthKey.text.trim();
      final paymentRes = await _api.get(
        'listSalaryPayments',
        query: _isValidMonthKey(month) ? {'monthKey': month} : null,
        forceRefresh: forceRefresh,
      );

      if (staffRes['ok'] == true) {
        _staff = ((staffRes['data'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList());
      }
      if (paymentRes['ok'] == true) {
        _payments = ((paymentRes['data'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList());
      }
      if (_staff.isNotEmpty && _selectedStaffId.isEmpty) {
        _selectedStaffId = _staff.first['id'].toString();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveStaff() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!_canWrite) {
      AccessControlService.showDeniedSnack(
        context,
        permission: AppPermissions.salaryWrite,
        routeName: '/salary',
      );
      return;
    }
    if (_staffName.text.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(
          content:
              Text(AppLang.t('কর্মীর নাম দিন', 'Staff name required'))));
      return;
    }
    final salary = double.tryParse(_staffSalary.text.trim()) ?? 0;
    if (salary <= 0) {
      messenger.showSnackBar(SnackBar(
          content: Text(AppLang.t('মাসিক বেতন ০ এর বেশি হতে হবে',
              'Monthly salary must be > 0'))));
      return;
    }

    final payload = {
      'id': 'staff_${DateTime.now().millisecondsSinceEpoch}',
      'staff_name': _staffName.text.trim(),
      'role': _staffRole.text.trim(),
      'monthly_salary': salary,
      'active': 'TRUE',
      'updated_by': SessionService.userId,
    };

    final res = await _api.post('upsertStaff', {
      'user_role': SessionService.role,
      'payload': payload,
    });

    if (!mounted) return;
    if (res['ok'] == true) {
      _staffName.clear();
      _staffRole.clear();
      _staffSalary.clear();
      await _loadAll();
      if (!mounted) return;
      final msg = res['queued'] == true
          ? AppLang.t('অফলাইনে সংরক্ষিত।', 'Offline saved. Will sync automatically.')
          : AppLang.t('কর্মী সংরক্ষিত', 'Staff saved');
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } else {
      messenger.showSnackBar(
          SnackBar(content: Text('${res['message'] ?? res['error']}')));
    }
  }

  Future<void> _recordPayment() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!_canWrite) {
      AccessControlService.showDeniedSnack(
        context,
        permission: AppPermissions.salaryWrite,
        routeName: '/salary',
      );
      return;
    }
    if (_selectedStaffId.isEmpty ||
        _paidAmount.text.trim().isEmpty ||
        _monthKey.text.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(
          content: Text(AppLang.t('কর্মী, মাস ও প্রদত্ত পরিমাণ দিন',
              'Staff, month, and paid amount required'))));
      return;
    }
    if (!_isValidMonthKey(_monthKey.text.trim())) {
      messenger.showSnackBar(SnackBar(
          content: Text(AppLang.t(
              'মাসের ফরম্যাট YYYY-MM দিন', 'Use month format YYYY-MM'))));
      return;
    }
    final payable = double.tryParse(_payableAmount.text.trim()) ?? 0;
    final paid = double.tryParse(_paidAmount.text.trim()) ?? 0;
    if (paid <= 0) {
      messenger.showSnackBar(SnackBar(
          content: Text(AppLang.t('প্রদত্ত পরিমাণ ০ এর বেশি হতে হবে',
              'Paid amount must be > 0'))));
      return;
    }
    if (payable > 0 && paid > payable) {
      messenger.showSnackBar(SnackBar(
          content: Text(AppLang.t(
              'প্রদত্ত পরিমাণ প্রদেয় পরিমাণের বেশি হতে পারে না',
              'Paid cannot exceed payable amount'))));
      return;
    }

    final selected = _staff.firstWhere(
        (s) => s['id'].toString() == _selectedStaffId,
        orElse: () => {});
    final staffName = selected['staff_name']?.toString() ?? 'Staff';

    final res = await _api.post('recordSalaryPayment', {
      'user_role': SessionService.role,
      'payload': {
        'staff_id': _selectedStaffId,
        'staff_name': staffName,
        'month_key': _monthKey.text.trim(),
        'payable_amount': payable,
        'paid_amount': paid,
        'due_amount': double.tryParse(_dueAmount.text.trim()) ?? 0,
        'fund_type': _fundType,
        'status': 'PAID',
        'created_by': SessionService.userId,
      }
    });

    if (!mounted) return;
    if (res['ok'] == true) {
      _paidAmount.clear();
      _payableAmount.clear();
      _dueAmount.text = '0';
      await _loadAll();
      if (!mounted) return;
      final msg = res['queued'] == true
          ? AppLang.t('অফলাইনে সংরক্ষিত।', 'Offline saved. Will sync automatically.')
          : AppLang.t('বেতন পরিশোধ নথিভুক্ত হয়েছে', 'Salary payment recorded');
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } else {
      messenger.showSnackBar(
          SnackBar(content: Text('${res['message'] ?? res['error']}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLang.isEnglish,
      builder: (context, isEn, _) => BaseScaffold(
        title: AppLang.t('বেতন', 'Salary'),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(AppLang.t('কর্মী যোগ করুন', 'Add Staff'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _staffName,
                      decoration: InputDecoration(
                          labelText:
                              AppLang.t('কর্মীর নাম', 'Staff Name'))),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _staffRole,
                      decoration: InputDecoration(
                          labelText:
                              AppLang.t('পদবী', 'Role/Designation'))),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _staffSalary,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText:
                              AppLang.t('মাসিক বেতন', 'Monthly Salary'))),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                      onPressed: _saveStaff,
                      icon: const Icon(Icons.person_add),
                      label: Text(
                          AppLang.t('কর্মী সংরক্ষণ', 'Save Staff'))),
                  const Divider(height: 28),
                  Text(
                      AppLang.t('বেতন প্রদান নথিভুক্ত করুন',
                          'Record Salary Payment'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue:
                        _selectedStaffId.isEmpty ? null : _selectedStaffId,
                    items: _staff
                        .map((s) => DropdownMenuItem(
                              value: s['id'].toString(),
                              child: Text(
                                  '${s['staff_name'] ?? ''} (${s['role'] ?? ''})'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _selectedStaffId = v ?? '');
                      final found = _staff.firstWhere(
                        (s) => s['id'].toString() == v,
                        orElse: () => {},
                      );
                      final monthlySalary = double.tryParse(
                              found['monthly_salary']?.toString() ?? '') ??
                          0;
                      if (monthlySalary > 0 && _payableAmount.text.trim().isEmpty) {
                        _payableAmount.text = monthlySalary == monthlySalary.truncateToDouble()
                            ? monthlySalary.toInt().toString()
                            : monthlySalary.toStringAsFixed(2);
                      }
                    },
                    decoration:
                        InputDecoration(labelText: AppLang.t('কর্মী', 'Staff')),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _monthKey,
                    decoration: InputDecoration(
                      labelText:
                          AppLang.t('মাস (YYYY-MM)', 'Month (YYYY-MM)'),
                      helperText: AppLang.t(
                          'ফিল্টার ও সংরক্ষণের মাস', 'Filter and save month'),
                    ),
                    onSubmitted: (_) => _reloadByMonth(),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _fundType,
                    items: [
                      DropdownMenuItem(
                          value: 'GENERAL',
                          child: Text(AppLang.t('সাধারণ', 'General'))),
                      DropdownMenuItem(
                          value: 'CONSTRUCTION',
                          child: Text(AppLang.t('নির্মাণ', 'Construction'))),
                      DropdownMenuItem(
                          value: 'JAKAT',
                          child: Text(AppLang.t('যাকাত', 'Jakat'))),
                      DropdownMenuItem(
                          value: 'SCHOLARSHIP',
                          child: Text(AppLang.t('বৃত্তি', 'Scholarship'))),
                    ],
                    onChanged: (v) => setState(() => _fundType = v ?? 'GENERAL'),
                    decoration: InputDecoration(
                        labelText: AppLang.t('ফান্ড ধরন', 'Fund Type')),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _payableAmount,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: AppLang.t(
                              'প্রদেয় পরিমাণ', 'Payable Amount'))),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _paidAmount,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText:
                              AppLang.t('প্রদত্ত পরিমাণ', 'Paid Amount'))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _dueAmount,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: AppLang.t(
                          'বাকি পরিমাণ (স্বয়ংক্রিয়)', 'Due Amount (auto)'),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                      onPressed: _recordPayment,
                      icon: const Icon(Icons.payments),
                      label: Text(AppLang.t(
                          'বেতন নথিভুক্ত করুন', 'Record Payment'))),
                  const Divider(height: 28),
                  Row(
                    children: [
                      Text(
                          AppLang.t('সাম্প্রতিক বেতন পরিশোধ',
                              'Recent Salary Payments'),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        tooltip: AppLang.t('নির্বাচিত মাস রিলোড করুন',
                            'Reload selected month'),
                        onPressed: () => _reloadByMonth(forceRefresh: true),
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  ..._payments.map(
                    (p) => Card(
                      child: ListTile(
                        title: Text(
                            '${p['staff_id'] ?? ''} • ৳${p['paid_amount'] ?? 0}'),
                        subtitle: Text(
                            '${p['month_key'] ?? ''} • ${p['payment_date'] ?? ''} • ${p['status'] ?? ''}'),
                        trailing: IconButton(
                          tooltip: AppLang.t('স্লিপ শেয়ার করুন', 'Share Slip'),
                          icon: const Icon(Icons.share),
                          onPressed: () {
                            final staffEntry = _staff.firstWhere(
                              (s) => s['id'].toString() == p['staff_id'].toString(),
                              orElse: () => {},
                            );
                            final name = staffEntry['staff_name'] ?? p['staff_id'] ?? '';
                            final role = staffEntry['role'] ?? '';
                            final slip = '''
--- বেতন স্লিপ ---
নাম: $name
পদবি: $role
মাস: ${p['month_key'] ?? ''}
প্রদেয়: ৳${p['payable_amount'] ?? 0}
প্রদত্ত: ৳${p['paid_amount'] ?? 0}
বাকি: ৳${p['due_amount'] ?? 0}
তারিখ: ${p['payment_date'] ?? ''}
অবস্থা: ${p['status'] ?? ''}
------------------''';
                            Share.share(slip, subject: AppLang.t('বেতন স্লিপ', 'Salary Slip'));
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
