import 'package:flutter/material.dart';

import '../../shared/services/api_service.dart';
import '../../shared/widgets/base_scaffold.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _api = ApiService();
  final _month = TextEditingController(text: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}');

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _data;

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.get('monthlyReport', query: {'monthKey': _month.text.trim()});
      if (res['ok'] == true) {
        _data = Map<String, dynamic>.from((res['data'] ?? {}) as Map);
      } else {
        _error = (res['message'] ?? res['error'] ?? 'Failed').toString();
      }
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    final rows = ((_data?['rows'] as List<dynamic>?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    return BaseScaffold(
      title: 'Reports & Share',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _month, decoration: const InputDecoration(labelText: 'Month Key (YYYY-MM)')),
          const SizedBox(height: 10),
          FilledButton.icon(onPressed: _loading ? null : _loadReport, icon: const Icon(Icons.summarize), label: const Text('Load Monthly Report')),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null) Text('Error: $_error', style: const TextStyle(color: Colors.red)),
          if (_data != null && !_loading) ...[
            Card(child: ListTile(title: const Text('Total In'), trailing: Text('৳${_data!['totalIn'] ?? 0}'))),
            Card(child: ListTile(title: const Text('Total Out'), trailing: Text('৳${_data!['totalOut'] ?? 0}'))),
            Card(child: ListTile(title: const Text('Balance'), trailing: Text('৳${_data!['balance'] ?? 0}'))),
            const SizedBox(height: 8),
            const Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...rows.take(100).map((r) => Card(
                  child: ListTile(
                    title: Text('${r['direction'] ?? ''} • ৳${r['amount'] ?? 0}'),
                    subtitle: Text('${r['fund_type'] ?? ''} • ${r['txn_date'] ?? ''} • ${r['category'] ?? ''}'),
                  ),
                )),
          ],
          const SizedBox(height: 12),
          const Text(
            'Print/Share placeholder: next phase এ PDF export + WhatsApp share text যোগ হবে।',
            style: TextStyle(fontSize: 12),
          )
        ],
      ),
    );
  }
}
