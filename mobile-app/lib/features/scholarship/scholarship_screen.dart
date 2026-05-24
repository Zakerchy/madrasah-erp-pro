import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
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

  String _monthKey = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
  late final TextEditingController _monthCtrl;
  String _selectedBeneficiaryId = '';
  String _selectedBeneficiaryName = '';
  String _fundType = 'SCHOLARSHIP';

  final _school = TextEditingController(text: '0');
  final _bangla = TextEditingController(text: '0');
  final _arabi = TextEditingController(text: '0');
  final _materials = TextEditingController(text: '0');
  final _other = TextEditingController(text: '0');
  final _remaining = TextEditingController(text: '0');
  String _status = 'PAID';

  @override
  void initState() {
    super.initState();
    _monthCtrl = TextEditingController(text: _monthKey);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);

    try {
      final benRes = await _api.get('listBeneficiaries');
      if (benRes['ok'] == true) {
        _beneficiaries = ((benRes['data'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList());
        if (_beneficiaries.isNotEmpty && _selectedBeneficiaryId.isEmpty) {
          _selectedBeneficiaryId = _beneficiaries.first['id'].toString();
          _selectedBeneficiaryName = _beneficiaries.first['name_bn'].toString();
        }
      }

      final payRes = await _api.get('listScholarshipByMonth', query: {'monthKey': _monthKey});
      if (payRes['ok'] == true) {
        _payments = ((payRes['data'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  double _n(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  Future<void> _savePayment() async {
    if (_selectedBeneficiaryId.isEmpty || _monthKey.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLang.t('সুবিধাভোগী ও মাস প্রয়োজন', 'Beneficiary and month are required'))));
      return;
    }

    final total = _n(_school) + _n(_bangla) + _n(_arabi) + _n(_materials) + _n(_other);

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
      _remaining.text = '0';
      await _loadAll();
      final msg = res['queued'] == true
          ? AppLang.t('অফলাইনে সংরক্ষিত।', 'Offline saved. Will sync automatically.')
          : AppLang.t('বৃত্তি পরিশোধ সংরক্ষিত', 'Scholarship payment saved');
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
        title: AppLang.t('বৃত্তি', 'Scholarship'),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(AppLang.t('বৃত্তি পরিশোধ নথিভুক্ত করুন', 'Record Scholarship Payment'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _monthCtrl,
                    decoration: InputDecoration(labelText: AppLang.t('মাস (YYYY-MM)', 'Month (YYYY-MM)')),
                    onChanged: (v) => _monthKey = v.trim(),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedBeneficiaryId.isEmpty ? null : _selectedBeneficiaryId,
                    items: _beneficiaries
                        .map((b) => DropdownMenuItem(
                              value: b['id'].toString(),
                              child: Text(b['name_bn']?.toString() ?? ''),
                            ))
                        .toList(),
                    onChanged: (v) {
                      final item = _beneficiaries.firstWhere((b) => b['id'].toString() == v, orElse: () => {});
                      setState(() {
                        _selectedBeneficiaryId = v ?? '';
                        _selectedBeneficiaryName = item['name_bn']?.toString() ?? '';
                      });
                    },
                    decoration: InputDecoration(labelText: AppLang.t('সুবিধাভোগী', 'Beneficiary')),
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: _school, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppLang.t('বিদ্যালয় বেতন', 'School Fee'))),
                  const SizedBox(height: 8),
                  TextField(controller: _bangla, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppLang.t('বাংলা প্রাইভেট', 'Bangla Tutor'))),
                  const SizedBox(height: 8),
                  TextField(controller: _arabi, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppLang.t('আরবি প্রাইভেট', 'Arabi Tutor'))),
                  const SizedBox(height: 8),
                  TextField(controller: _materials, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppLang.t('শিক্ষাসামগ্রী', 'Materials'))),
                  const SizedBox(height: 8),
                  TextField(controller: _other, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppLang.t('অন্যান্য', 'Other'))),
                  const SizedBox(height: 8),
                  TextField(controller: _remaining, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppLang.t('বাকি পরিমাণ', 'Remaining Amount'))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _status,
                    items: [
                      DropdownMenuItem(value: 'PAID', child: Text(AppLang.t('পরিশোধিত', 'PAID'))),
                      DropdownMenuItem(value: 'PARTIAL', child: Text(AppLang.t('আংশিক', 'PARTIAL'))),
                      DropdownMenuItem(value: 'CANCELLED', child: Text(AppLang.t('বাতিল', 'CANCELLED'))),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'PAID'),
                    decoration: InputDecoration(labelText: AppLang.t('অবস্থা', 'Status')),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _fundType,
                    items: [
                      DropdownMenuItem(value: 'SCHOLARSHIP', child: Text(AppLang.t('বৃত্তি ফান্ড', 'Scholarship Fund'))),
                      DropdownMenuItem(value: 'JAKAT', child: Text(AppLang.t('যাকাত ফান্ড', 'Jakat Fund'))),
                      DropdownMenuItem(value: 'GENERAL', child: Text(AppLang.t('সাধারণ ফান্ড', 'General Fund'))),
                    ],
                    onChanged: (v) => setState(() => _fundType = v ?? 'SCHOLARSHIP'),
                    decoration: InputDecoration(labelText: AppLang.t('ফান্ড ধরন', 'Fund Type')),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: _savePayment, icon: const Icon(Icons.save), label: Text(AppLang.t('পরিশোধ সংরক্ষণ', 'Save Payment'))),
                  const Divider(height: 28),
                  Row(
                    children: [
                      Text('${AppLang.t('পরিশোধ', 'Payments')} $_monthKey', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh)),
                    ],
                  ),
                  ..._payments.map(
                    (p) => Card(
                      child: ListTile(
                        title: Text('${p['notes'] ?? p['beneficiary_id'] ?? ''} • ৳${p['total_paid'] ?? 0}'),
                        subtitle: Text('${p['month_key'] ?? ''} • ${p['payment_status'] ?? ''} • ${p['payment_date'] ?? ''}'),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
