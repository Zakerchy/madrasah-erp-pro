import 'package:flutter/material.dart';

import '../../shared/models/dashboard_summary.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  DashboardSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.get('dashboardSummary');
      if (res['ok'] == true) {
        _summary = DashboardSummary.fromMap((res['data'] ?? {}) as Map<String, dynamic>);
      } else {
        _error = (res['message'] ?? res['error'] ?? 'Failed').toString();
      }
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (SessionService.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      });
    }

    return BaseScaffold(
      title: 'Dashboard',
      actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _KpiCard(title: 'Total In', value: _format(_summary?.totalIn ?? 0)),
                    _KpiCard(title: 'Total Out', value: _format(_summary?.totalOut ?? 0)),
                    _KpiCard(title: 'Balance', value: _format(_summary?.balance ?? 0)),
                    const SizedBox(height: 12),
                    const Text('Fund-wise Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...(_summary?.byFund.entries ?? []).map(
                      (e) => Card(
                        child: ListTile(
                          title: Text(e.key),
                          subtitle: Text('In: ${_format(e.value.incoming)} | Out: ${_format(e.value.outgoing)}'),
                          trailing: Text(_format(e.value.balance), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _quickBtn('Add Donation', '/donations'),
                        _quickBtn('Add Expense', '/expenses'),
                        _quickBtn('Salary', '/salary'),
                        _quickBtn('Scholarship', '/scholarship'),
                        _quickBtn('Beneficiaries', '/beneficiaries'),
                        _quickBtn('Reports', '/reports'),
                      ],
                    ),
                  ],
                ),
    );
  }

  Widget _quickBtn(String label, String route) {
    return FilledButton(
      onPressed: () => Navigator.pushReplacementNamed(context, route),
      child: Text(label),
    );
  }

  String _format(double n) => '৳${n.toStringAsFixed(0)}';
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  const _KpiCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
