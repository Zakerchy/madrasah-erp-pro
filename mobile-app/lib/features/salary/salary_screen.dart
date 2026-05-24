import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
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
  final _monthKey = TextEditingController(text: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}');
  final _paidAmount = TextEditingController();
  final _payableAmount = TextEditingController();
  final _dueAmount = TextEditingController(text: '0');
  String _fundType = 'GENERAL';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  bool _isValidMonthKey(String value) {
    return RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(value.trim());
  }

  Future<void> _reloadByMonth() async {
    final month = _monthKey.text.trim();
    if (!_isValidMonthKey(month)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLang.t('মাসের ফরম্যাট YYYY-MM দিন', 'Use month format YYYY-MM'))),
      );
      return;
    }
    await _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final staffRes = await _api.get('listStaff');
      final month = _monthKey.text.trim();
      final paymentRes = await _api.get(
        'listSalaryPayments',
        query: _isValidMonthKey(month) ? {'monthKey': month} : null,
      );

      if (staffRes['ok'] == true) {
        _staff = ((staffRes['data'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
      if (paymentRes['ok'] == true) {
        _payments = ((paymentRes['data'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
      if (_staff.isNotEmpty && _selectedStaffId.isEmpty) {
        _selectedStaffId = _staff.first['id'].toString();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveStaff() async {
    if (_staffName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLang.t('কর্মীর নাম দিন', 'Staff name required'))));
      return;
    }

    final payload = {
      'id': 'staff_${DateTime.now().millisecondsSinceEpoch}',
      'staff_name': _staffName.text.trim(),
      'role': _staffRole.text.trim(),
      'monthly_salary': double.tryParse(_staffSalary.text.trim()) ?? 0,
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
      final msg = res['queued'] == true
          ? AppLang.t('অফলাইনে সংরক্ষিত।', 'Offline saved. Will sync automatically.')
          : AppLang.t('কর্মী সংরক্ষিত', 'Staff saved');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${res['message'] ?? res['error']}')));
    }
  }

  Future<void> _recordPayment() async {
    if (_selectedStaffId.isEmpty || _paidAmount.text.trim().isEmpty || _monthKey.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLang.t('কর্মী, মাস ও প্রদত্ত পরিমাণ দিন', 'Staff, month, and paid amount required'))));
      return;
    }

    final selected = _staff.firstWhere((s) => s['id'].toString() == _selectedStaffId, orElse: () => {});
    final staffName = selected['staff_name']?.toString() ?? 'Staff';

    final res = await _api.post('recordSalaryPayment', {
      'user_role': SessionService.role,
      'payload': {
        'staff_id': _selectedStaffId,
        'staff_name': staffName,
        'month_key': _monthKey.text.trim(),
        'payable_amount': double.tryParse(_payableAmount.text.trim()) ?? 0,
        'paid_amount': double.tryParse(_paidAmount.text.trim()) ?? 0,
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
      final msg = res['queued'] == true
          ? AppLang.t('অফলাইনে সংরক্ষিত।', 'Offline saved. Will sync automatically.')
          : AppLang.t('বেতন পরিশোধ নথিভুক্ত হয়েছে', 'Salary payment recorded');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${res['message'] ?? res['error']}')));
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
                  Text(AppLang.t('কর্মী যোগ করুন', 'Add Staff'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(controller: _staffName, decoration: InputDecoration(labelText: AppLang.t('কর্মীর নাম', 'Staff Name'))),
                  const SizedBox(height: 8),
                  TextField(controller: _staffRole, decoration: InputDecoration(labelText: AppLang.t('পদবী', 'Role/Designation'))),
                  const SizedBox(height: 8),
                  TextField(controller: _staffSalary, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppLang.t('মাসিক বেতন', 'Monthly Salary'))),
                  const SizedBox(height: 10),
                  FilledButton.icon(onPressed: _saveStaff, icon: const Icon(Icons.person_add), label: Text(AppLang.t('কর্মী সংরক্ষণ', 'Save Staff'))),
                  const Divider(height: 28),
                  Text(AppLang.t('বেতন প্রদান নথিভুক্ত করুন', 'Record Salary Payment'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedStaffId.isEmpty ? null : _selectedStaffId,
                    items: _staff
                        .map((s) => DropdownMenuItem(
                              value: s['id'].toString(),
                              child: Text('${s['staff_name'] ?? ''} (${s['role'] ?? ''})'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedStaffId = v ?? ''),
                    decoration: InputDecoration(labelText: AppLang.t('কর্মী', 'Staff')),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _monthKey,
                    decoration: InputDecoration(
                      labelText: AppLang.t('মাস (YYYY-MM)', 'Month (YYYY-MM)'),
                      helperText: AppLang.t('ফিল্টার ও সংরক্ষণের মাস', 'Filter and save month'),
                    ),
                    onSubmitted: (_) => _reloadByMonth(),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _fundType,
                    items: [
                      DropdownMenuItem(value: 'GENERAL', child: Text(AppLang.t('সাধারণ', 'General'))),
                      DropdownMenuItem(value: 'CONSTRUCTION', child: Text(AppLang.t('নির্মাণ', 'Construction'))),
                      DropdownMenuItem(value: 'JAKAT', child: Text(AppLang.t('যাকাত', 'Jakat'))),
                      DropdownMenuItem(value: 'SCHOLARSHIP', child: Text(AppLang.t('বৃত্তি', 'Scholarship'))),
                    ],
                    onChanged: (v) => setState(() => _fundType = v ?? 'GENERAL'),
                    decoration: InputDecoration(labelText: AppLang.t('ফান্ড ধরন', 'Fund Type')),
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: _payableAmount, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppLang.t('প্রদেয় পরিমাণ', 'Payable Amount'))),
                  const SizedBox(height: 8),
                  TextField(controller: _paidAmount, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppLang.t('প্রদত্ত পরিমাণ', 'Paid Amount'))),
                  const SizedBox(height: 8),
                  TextField(controller: _dueAmount, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppLang.t('বাকি পরিমাণ', 'Due Amount'))),
                  const SizedBox(height: 10),
                  FilledButton.icon(onPressed: _recordPayment, icon: const Icon(Icons.payments), label: Text(AppLang.t('বেতন নথিভুক্ত করুন', 'Record Payment'))),
                  const Divider(height: 28),
                  Row(
                    children: [
                      Text(AppLang.t('সাম্প্রতিক বেতন পরিশোধ', 'Recent Salary Payments'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        tooltip: AppLang.t('নির্বাচিত মাস রিলোড করুন', 'Reload selected month'),
                        onPressed: _reloadByMonth,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  ..._payments.map(
                    (p) => Card(
                      child: ListTile(
                        title: Text('${p['staff_id'] ?? ''} • ৳${p['paid_amount'] ?? 0}'),
                        subtitle: Text('${p['month_key'] ?? ''} • ${p['payment_date'] ?? ''} • ${p['status'] ?? ''}'),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
