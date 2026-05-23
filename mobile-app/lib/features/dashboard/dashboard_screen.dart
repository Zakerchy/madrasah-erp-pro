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
  DateTime? _lastBackPressedAt;

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
        _summary = DashboardSummary.fromMap(
            (res['data'] ?? {}) as Map<String, dynamic>);
      } else {
        _error = (res['message'] ?? res['error'] ?? 'Failed').toString();
      }
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressedAt == null ||
        now.difference(_lastBackPressedAt!) > const Duration(seconds: 2)) {
      _lastBackPressedAt = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Press back again to exit dashboard')),
      );
      return false;
    }
    return true;
  }

  Future<void> _openQuickEntry({required bool income}) async {
    final formKey = GlobalKey<FormState>();
    final date = TextEditingController(
        text: DateTime.now().toIso8601String().split('T').first);
    final amount = TextEditingController();
    final source = TextEditingController();
    final note = TextEditingController();
    var fundType = 'GENERAL';

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(income ? 'Quick Add Donation' : 'Quick Add Expense'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: date,
                        decoration: const InputDecoration(
                            labelText: 'Date (YYYY-MM-DD)'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: fundType,
                        items: const [
                          DropdownMenuItem(
                              value: 'CONSTRUCTION',
                              child: Text('CONSTRUCTION')),
                          DropdownMenuItem(
                              value: 'JAKAT', child: Text('JAKAT')),
                          DropdownMenuItem(
                              value: 'SCHOLARSHIP', child: Text('SCHOLARSHIP')),
                          DropdownMenuItem(
                              value: 'GENERAL', child: Text('GENERAL')),
                        ],
                        onChanged: (v) =>
                            setStateDialog(() => fundType = v ?? 'GENERAL'),
                        decoration:
                            const InputDecoration(labelText: 'Fund Type'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: amount,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(labelText: 'Amount'),
                        validator: (v) {
                          final n = double.tryParse((v ?? '').trim()) ?? 0;
                          return n <= 0 ? 'Must be > 0' : null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: source,
                        decoration: InputDecoration(
                            labelText: income ? 'Donor' : 'Vendor'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: note,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Note'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate())
                      Navigator.pop(context, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    final res = await _api.post('createTransaction', {
      'user_role': SessionService.role,
      'payload': {
        'txn_date': date.text.trim(),
        'direction': income ? 'IN' : 'OUT',
        'fund_type': fundType,
        'amount': double.tryParse(amount.text.trim()) ?? 0,
        'source_or_vendor': source.text.trim(),
        'category': income ? 'DONATION' : 'EXPENSE',
        'notes': note.text.trim(),
        'created_by': SessionService.userId,
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '${res['message'] ?? (res['ok'] == true ? 'Saved' : 'Failed')}')),
    );
    if (res['ok'] == true) await _load();
  }

  void _handleAction(String action) {
    switch (action) {
      case 'donation':
        _openQuickEntry(income: true);
        return;
      case 'expense':
        _openQuickEntry(income: false);
        return;
      case 'salary':
        Navigator.pushNamed(context, '/salary');
        return;
      case 'scholarship':
        Navigator.pushNamed(context, '/scholarship');
        return;
      case 'beneficiaries':
        Navigator.pushNamed(context, '/beneficiaries');
        return;
      case 'reports':
        Navigator.pushNamed(context, '/reports');
        return;
      case 'settings':
        Navigator.pushNamed(context, '/settings');
        return;
    }
  }

  FundSummary _fund(String key) {
    return _summary?.byFund[key] ??
        FundSummary(incoming: 0, outgoing: 0, balance: 0);
  }

  String _format(double n) => '৳${n.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    if (SessionService.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
      });
    }

    final jakat = _fund('JAKAT');
    final construction = _fund('CONSTRUCTION');
    final scholarship = _fund('SCHOLARSHIP');
    final general = _fund('GENERAL');

    return WillPopScope(
      onWillPop: _onWillPop,
      child: BaseScaffold(
        title: 'Dashboard',
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          PopupMenuButton<String>(
            onSelected: _handleAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'donation', child: Text('Quick Donation Entry')),
              const PopupMenuItem(
                  value: 'expense', child: Text('Quick Expense Entry')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'salary', child: Text('Open Salary')),
              const PopupMenuItem(
                  value: 'scholarship', child: Text('Open Scholarship')),
              const PopupMenuItem(
                  value: 'beneficiaries', child: Text('Open Beneficiaries')),
              const PopupMenuItem(
                  value: 'reports', child: Text('Open Reports')),
              if (SessionService.role == 'ADMIN')
                const PopupMenuItem(
                    value: 'settings', child: Text('Open Settings')),
            ],
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Assalamu Alaikum, ${SessionService.userName}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                  'Role: ${SessionService.role} • Gmail: ${SessionService.user?.email ?? ''}',
                                  style:
                                      TextStyle(color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.8,
                        children: [
                          _MetricTile(
                              title: 'Total Fund',
                              value: _format(_summary?.balance ?? 0),
                              color: Colors.teal),
                          _MetricTile(
                              title: 'Total Jakat Fund',
                              value: _format(jakat.incoming),
                              color: Colors.indigo),
                          _MetricTile(
                              title: 'Jakat Expenses',
                              value: _format(jakat.outgoing),
                              color: Colors.redAccent),
                          _MetricTile(
                              title: 'Overall Expense',
                              value: _format(_summary?.totalOut ?? 0),
                              color: Colors.orange),
                          _MetricTile(
                              title: 'Construction Balance',
                              value: _format(construction.balance),
                              color: Colors.blue),
                          _MetricTile(
                              title: 'Scholarship Balance',
                              value: _format(scholarship.balance),
                              color: Colors.purple),
                          _MetricTile(
                              title: 'General Balance',
                              value: _format(general.balance),
                              color: Colors.green),
                          _MetricTile(
                              title: 'Total Collection',
                              value: _format(_summary?.totalIn ?? 0),
                              color: Colors.brown),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text('Fund Flow Details',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...(_summary?.byFund.entries ?? []).map(
                        (e) => Card(
                          child: ListTile(
                            title: Text(e.key),
                            subtitle: Text(
                                'In: ${_format(e.value.incoming)} | Out: ${_format(e.value.outgoing)}'),
                            trailing: Text(_format(e.value.balance),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricTile(
      {required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: color.withOpacity(0.95))),
          const SizedBox(height: 5),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
