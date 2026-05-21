import 'package:flutter/material.dart';

import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';

class BeneficiariesScreen extends StatefulWidget {
  const BeneficiariesScreen({super.key});

  @override
  State<BeneficiariesScreen> createState() => _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends State<BeneficiariesScreen> {
  final _api = ApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];

  final _name = TextEditingController();
  final _age = TextEditingController();
  final _className = TextEditingController();
  final _guardianStatus = TextEditingController();
  final _monthlyAmount = TextEditingController();

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('listBeneficiaries');
      if (res['ok'] == true) {
        final data = (res['data'] as List<dynamic>? ?? []);
        _rows = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    final payload = {
      'id': 'ben_${DateTime.now().millisecondsSinceEpoch}',
      'name_bn': _name.text.trim(),
      'age': _age.text.trim(),
      'class_name': _className.text.trim(),
      'guardian_status': _guardianStatus.text.trim(),
      'monthly_need_amount': double.tryParse(_monthlyAmount.text.trim()) ?? 0,
      'active': 'TRUE',
      'updated_by': SessionService.userId,
    };

    final res = await _api.post('upsertBeneficiary', {
      'user_role': SessionService.role,
      'payload': payload,
    });

    if (!mounted) return;
    if (res['ok'] == true) {
      _name.clear();
      _age.clear();
      _className.clear();
      _guardianStatus.clear();
      _monthlyAmount.clear();
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Beneficiary saved')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${res['message'] ?? res['error']}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Beneficiaries',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Add Beneficiary', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name (Bangla)')),
          const SizedBox(height: 8),
          TextField(controller: _age, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age')),
          const SizedBox(height: 8),
          TextField(controller: _className, decoration: const InputDecoration(labelText: 'Class')),
          const SizedBox(height: 8),
          TextField(controller: _guardianStatus, decoration: const InputDecoration(labelText: 'Guardian Status')),
          const SizedBox(height: 8),
          TextField(controller: _monthlyAmount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Need Amount')),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save Beneficiary')),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Beneficiary List', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
          ),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else
            ..._rows.map(
              (r) => Card(
                child: ListTile(
                  title: Text(r['name_bn']?.toString() ?? 'Unnamed'),
                  subtitle: Text('Class: ${r['class_name'] ?? '-'} | Monthly: ৳${r['monthly_need_amount'] ?? 0}'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
