import 'package:flutter/material.dart';

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

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final staffRes = await _api.get('listStaff');
      final paymentRes = await _api.get('listSalaryPayments');

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff name required')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff saved')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${res['message'] ?? res['error']}')));
    }
  }

  Future<void> _recordPayment() async {
    if (_selectedStaffId.isEmpty || _paidAmount.text.trim().isEmpty || _monthKey.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff, month, and paid amount required')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salary payment recorded')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${res['message'] ?? res['error']}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Salary',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Add Staff', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(controller: _staffName, decoration: const InputDecoration(labelText: 'Staff Name')),
                const SizedBox(height: 8),
                TextField(controller: _staffRole, decoration: const InputDecoration(labelText: 'Role/Designation')),
                const SizedBox(height: 8),
                TextField(controller: _staffSalary, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Salary')),
                const SizedBox(height: 10),
                FilledButton.icon(onPressed: _saveStaff, icon: const Icon(Icons.person_add), label: const Text('Save Staff')),
                const Divider(height: 28),
                const Text('Record Salary Payment', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  decoration: const InputDecoration(labelText: 'Staff'),
                ),
                const SizedBox(height: 8),
                TextField(controller: _monthKey, decoration: const InputDecoration(labelText: 'Month Key (YYYY-MM)')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _fundType,
                  items: const [
                    DropdownMenuItem(value: 'GENERAL', child: Text('General')),
                    DropdownMenuItem(value: 'CONSTRUCTION', child: Text('Construction')),
                    DropdownMenuItem(value: 'JAKAT', child: Text('Jakat')),
                    DropdownMenuItem(value: 'SCHOLARSHIP', child: Text('Scholarship')),
                  ],
                  onChanged: (v) => setState(() => _fundType = v ?? 'GENERAL'),
                  decoration: const InputDecoration(labelText: 'Fund Type'),
                ),
                const SizedBox(height: 8),
                TextField(controller: _payableAmount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Payable Amount')),
                const SizedBox(height: 8),
                TextField(controller: _paidAmount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Paid Amount')),
                const SizedBox(height: 8),
                TextField(controller: _dueAmount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Due Amount')),
                const SizedBox(height: 10),
                FilledButton.icon(onPressed: _recordPayment, icon: const Icon(Icons.payments), label: const Text('Record Payment')),
                const Divider(height: 28),
                Row(
                  children: [
                    const Text('Recent Salary Payments', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh)),
                  ],
                ),
                ..._payments.map(
                  (p) => Card(
                    child: ListTile(
                      title: Text('Staff ID: ${p['staff_id'] ?? ''} • ৳${p['paid_amount'] ?? 0}'),
                      subtitle: Text('${p['month_key'] ?? ''} • ${p['payment_date'] ?? ''} • ${p['status'] ?? ''}'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
