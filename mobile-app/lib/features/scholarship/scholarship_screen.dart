import 'package:flutter/material.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Beneficiary and month are required')));
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
          ? 'Offline saved. Scholarship payment will sync automatically later.'
          : 'Scholarship payment saved';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${res['message'] ?? res['error']}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Scholarship',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Record Scholarship Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _monthCtrl,
                  decoration: const InputDecoration(labelText: 'Month Key (YYYY-MM)'),
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
                  decoration: const InputDecoration(labelText: 'Beneficiary'),
                ),
                const SizedBox(height: 8),
                TextField(controller: _school, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'School Fee')),
                const SizedBox(height: 8),
                TextField(controller: _bangla, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bangla Tutor')),
                const SizedBox(height: 8),
                TextField(controller: _arabi, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Arabi Tutor')),
                const SizedBox(height: 8),
                TextField(controller: _materials, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Materials')),
                const SizedBox(height: 8),
                TextField(controller: _other, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Other')),
                const SizedBox(height: 8),
                TextField(controller: _remaining, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Remaining Amount')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: 'PAID', child: Text('PAID')),
                    DropdownMenuItem(value: 'PARTIAL', child: Text('PARTIAL')),
                    DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'PAID'),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _fundType,
                  items: const [
                    DropdownMenuItem(value: 'SCHOLARSHIP', child: Text('Scholarship Fund')),
                    DropdownMenuItem(value: 'JAKAT', child: Text('Jakat Fund')),
                    DropdownMenuItem(value: 'GENERAL', child: Text('General Fund')),
                  ],
                  onChanged: (v) => setState(() => _fundType = v ?? 'SCHOLARSHIP'),
                  decoration: const InputDecoration(labelText: 'Fund Type'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(onPressed: _savePayment, icon: const Icon(Icons.save), label: const Text('Save Payment')),
                const Divider(height: 28),
                Row(
                  children: [
                    Text('Payments of $_monthKey', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh)),
                  ],
                ),
                ..._payments.map(
                  (p) => Card(
                    child: ListTile(
                      title: Text('${p['beneficiary_id'] ?? ''} • ৳${p['total_paid'] ?? 0}'),
                      subtitle: Text('${p['month_key'] ?? ''} • ${p['payment_status'] ?? ''} • ${p['payment_date'] ?? ''}'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
