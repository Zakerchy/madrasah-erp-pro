import 'package:flutter/material.dart';

import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _date = TextEditingController();
  final _amount = TextEditingController();
  final _source = TextEditingController();
  final _note = TextEditingController();

  String _fundType = 'CONSTRUCTION';
  bool _saving = false;
  bool _loadingList = true;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _date.text = DateTime.now().toIso8601String().split('T').first;
    _loadRows();
  }

  Future<void> _loadRows() async {
    setState(() => _loadingList = true);
    try {
      final res = await _api.get('listTransactions', query: {'direction': 'IN'});
      if (res['ok'] == true) {
        final data = (res['data'] as List<dynamic>? ?? []);
        _rows = data.take(30).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingList = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final res = await _api.post('createTransaction', {
        'user_role': SessionService.role,
        'payload': {
          'txn_date': _date.text.trim(),
          'direction': 'IN',
          'fund_type': _fundType,
          'amount': double.tryParse(_amount.text.trim()) ?? 0,
          'source_or_vendor': _source.text.trim(),
          'category': 'DONATION',
          'notes': _note.text.trim(),
          'created_by': SessionService.userId,
        }
      });

      if (!mounted) return;
      if (res['ok'] == true) {
        _amount.clear();
        _source.clear();
        _note.clear();
        await _loadRows();
        final msg = res['queued'] == true
            ? 'Offline saved. Donation will sync automatically later.'
            : 'Donation saved successfully';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res['message'] ?? res['error']}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Donations',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _date,
                  decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Date required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _fundType,
                  items: const [
                    DropdownMenuItem(value: 'CONSTRUCTION', child: Text('Construction')),
                    DropdownMenuItem(value: 'JAKAT', child: Text('Jakat')),
                    DropdownMenuItem(value: 'SCHOLARSHIP', child: Text('Scholarship')),
                    DropdownMenuItem(value: 'GENERAL', child: Text('General')),
                  ],
                  onChanged: (v) => setState(() => _fundType = v ?? 'CONSTRUCTION'),
                  decoration: const InputDecoration(labelText: 'Fund Type'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').trim()) ?? 0;
                    return n <= 0 ? 'Amount must be greater than 0' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _source,
                  decoration: const InputDecoration(labelText: 'Donor Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Donor required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Saving...' : 'Save Donation'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Recent Donations', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: _loadRows, icon: const Icon(Icons.refresh)),
            ],
          ),
          if (_loadingList)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ..._rows.map((r) => Card(
                  child: ListTile(
                    title: Text('${r['source_or_vendor'] ?? 'Donor'} • ৳${r['amount'] ?? 0}'),
                    subtitle: Text('${r['fund_type'] ?? ''} • ${r['txn_date'] ?? ''}'),
                  ),
                )),
        ],
      ),
    );
  }
}
