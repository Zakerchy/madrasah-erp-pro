import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';

class FinanceControlScreen extends StatefulWidget {
  const FinanceControlScreen({super.key});

  @override
  State<FinanceControlScreen> createState() => _FinanceControlScreenState();
}

class _FinanceControlScreenState extends State<FinanceControlScreen> {
  final _api = ApiService();
  bool _loading = true;
  bool _saving = false;
  int _tabIndex = 0;

  String _monthKey = '';
  String _fundType = 'GENERAL';
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _budgets = [];
  List<Map<String, dynamic>> _approvalRequests = [];
  List<Map<String, dynamic>> _approvalRules = [];

  final _plannedIn = TextEditingController();
  final _plannedOut = TextEditingController();
  final _budgetNotes = TextEditingController();
  final _ruleThreshold = TextEditingController(text: '5000');
  final _requestAmount = TextEditingController();
  final _requestSummary = TextEditingController();

  bool get _isAdmin => SessionService.role == 'ADMIN';
  bool get _canWrite => _isAdmin || SessionService.role == 'ACCOUNTANT';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _loadAll();
  }

  @override
  void dispose() {
    _plannedIn.dispose();
    _plannedOut.dispose();
    _budgetNotes.dispose();
    _ruleThreshold.dispose();
    _requestAmount.dispose();
    _requestSummary.dispose();
    super.dispose();
  }

  Future<void> _loadAll({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    final responses = await Future.wait([
      _api.get('financeControlSummary',
          query: {'month_key': _monthKey}, forceRefresh: forceRefresh),
      _api.get('listBudgets',
          query: {'month_key': _monthKey}, forceRefresh: forceRefresh),
      _api.get('listApprovalRequests', forceRefresh: forceRefresh),
      _api.get('listApprovalRules', forceRefresh: forceRefresh),
    ]);
    if (!mounted) return;
    if (responses[0]['ok'] == true) {
      _summary = Map<String, dynamic>.from(responses[0]['data'] as Map);
    }
    if (responses[1]['ok'] == true) _budgets = _rows(responses[1]);
    if (responses[2]['ok'] == true) _approvalRequests = _rows(responses[2]);
    if (responses[3]['ok'] == true) _approvalRules = _rows(responses[3]);
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _rows(Map<String, dynamic> res) {
    return (res['data'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _saveBudget() async {
    await _post(
        'upsertBudget',
        {
          'month_key': _monthKey,
          'fund_type': _fundType,
          'planned_in': double.tryParse(_plannedIn.text.trim()) ?? 0,
          'planned_out': double.tryParse(_plannedOut.text.trim()) ?? 0,
          'notes': _budgetNotes.text.trim(),
          'updated_by': SessionService.userId,
        },
        AppLang.t('Budget saved', 'Budget saved'));
    _plannedIn.clear();
    _plannedOut.clear();
    _budgetNotes.clear();
  }

  Future<void> _saveRule() async {
    await _post(
        'upsertApprovalRule',
        {
          'action_type': 'HIGH_VALUE_PAYMENT',
          'threshold_amount': double.tryParse(_ruleThreshold.text.trim()) ?? 0,
          'approver_role': 'ADMIN',
          'active': 'TRUE',
          'updated_by': SessionService.userId,
        },
        AppLang.t('Approval rule saved', 'Approval rule saved'));
  }

  Future<void> _createRequest() async {
    if (_requestSummary.text.trim().isEmpty) {
      _snack(AppLang.t('Summary প্রয়োজন', 'Summary is required'));
      return;
    }
    await _post(
        'createApprovalRequest',
        {
          'action_type': 'HIGH_VALUE_PAYMENT',
          'amount': double.tryParse(_requestAmount.text.trim()) ?? 0,
          'summary': _requestSummary.text.trim(),
          'entity_type': 'MANUAL',
        },
        AppLang.t('Approval request created', 'Approval request created'));
    _requestAmount.clear();
    _requestSummary.clear();
  }

  Future<void> _decide(String id, String decision) async {
    await _post(
        'decideApprovalRequest',
        {
          'id': id,
          'decision': decision,
          'decision_notes': decision,
        },
        AppLang.t('Decision saved', 'Decision saved'));
  }

  Future<void> _post(
      String action, Map<String, dynamic> payload, String okMsg) async {
    setState(() => _saving = true);
    final res = await _api.post(action, {
      'user_role': SessionService.role,
      'user_id': SessionService.userId,
      'payload': payload,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (res['ok'] == true) {
      await _loadAll();
      _snack(res['queued'] == true
          ? AppLang.t('Offline saved', 'Offline saved')
          : okMsg);
    } else {
      _snack('${res['message'] ?? res['error'] ?? 'Failed'}');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLang.isEnglish,
      builder: (context, isEn, _) => BaseScaffold(
        title: AppLang.t('ফাইন্যান্স কন্ট্রোল', 'Finance Control'),
        actions: [
          IconButton(
              onPressed: _loading ? null : () => _loadAll(forceRefresh: true),
              icon: const Icon(Icons.refresh))
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                return ListView(
                  padding: EdgeInsets.all(wide ? 24 : 14),
                  children: [
                    _hero(wide),
                    const SizedBox(height: 14),
                    _monthAndTabs(),
                    const SizedBox(height: 14),
                    switch (_tabIndex) {
                      0 => _reconciliationPanel(),
                      1 => _budgetPanel(),
                      _ => _approvalPanel(),
                    },
                  ],
                );
              }),
      ),
    );
  }

  Widget _hero(bool wide) {
    final totals = Map<String, dynamic>.from(_summary['totals'] as Map? ?? {});
    final reconciliation =
        Map<String, dynamic>.from(_summary['reconciliation'] as Map? ?? {});
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF172033), Color(0xFF2D5D7B), Color(0xFF8DD3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(wide ? 24 : 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              AppLang.t('Budget, Reconciliation & Approvals',
                  'Budget, Reconciliation & Approvals'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
              AppLang.t(
                  'Opening/closing balance, budget variance ও approval queue।',
                  'Opening/closing balance, budget variance, and approval queue.'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.88))),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: [
            _metric('In', totals['actual_in'] ?? 0),
            _metric('Out', totals['actual_out'] ?? 0),
            _metric('Closing', totals['closing_balance'] ?? 0),
            _metric(reconciliation['pass'] == true ? 'Recon OK' : 'Recon Check',
                reconciliation['pass'] == true ? 'PASS' : 'REVIEW'),
          ]),
        ]),
      ),
    );
  }

  Widget _metric(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18))),
      child: Text('$label: $value',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }

  Widget _monthAndTabs() {
    final tabs = [
      (Icons.balance, AppLang.t('Reconcile', 'Reconcile')),
      (Icons.savings, AppLang.t('Budget', 'Budget')),
      (Icons.verified_user, AppLang.t('Approval', 'Approval')),
    ];
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 180,
                child: TextField(
                  controller: TextEditingController(text: _monthKey),
                  decoration:
                      InputDecoration(labelText: AppLang.t('মাস', 'Month')),
                  onSubmitted: (v) {
                    setState(() => _monthKey = v.trim());
                    _loadAll();
                  },
                ),
              ),
              ...List.generate(
                  tabs.length,
                  (i) => ChoiceChip(
                      selected: _tabIndex == i,
                      avatar: Icon(tabs[i].$1, size: 18),
                      label: Text(tabs[i].$2),
                      onSelected: (_) => setState(() => _tabIndex = i))),
            ]),
      ),
    );
  }

  Widget _panel(String title, Widget child) {
    return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              child
            ])));
  }

  Widget _reconciliationPanel() {
    final rows = (_summary['rows'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return _panel(
        AppLang.t('Reconciliation Center', 'Reconciliation Center'),
        Column(
            children: rows
                .map((r) => Card(
                    elevation: 0,
                    child: ListTile(
                        title: Text(r['fund_type']?.toString() ?? '-'),
                        subtitle: Text(
                            'Open: ${r['opening_balance']} • In: ${r['actual_in']} • Out: ${r['actual_out']}'),
                        trailing: Text('Close: ${r['closing_balance']}'))))
                .toList()));
  }

  Widget _budgetPanel() {
    return _panel(
        AppLang.t('Monthly Budget', 'Monthly Budget'),
        Column(children: [
          DropdownButtonFormField<String>(
              initialValue: _fundType,
              items: ['GENERAL', 'CONSTRUCTION', 'JAKAT', 'SCHOLARSHIP']
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _fundType = v ?? 'GENERAL'),
              decoration:
                  InputDecoration(labelText: AppLang.t('Fund', 'Fund'))),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _plannedIn,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: AppLang.t('Planned In', 'Planned In')))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    controller: _plannedOut,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: AppLang.t('Planned Out', 'Planned Out'))))
          ]),
          TextField(
              controller: _budgetNotes,
              decoration:
                  InputDecoration(labelText: AppLang.t('Notes', 'Notes'))),
          const SizedBox(height: 10),
          Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                  onPressed: !_canWrite || _saving ? null : _saveBudget,
                  icon: const Icon(Icons.save),
                  label: Text(AppLang.t('Save Budget', 'Save Budget')))),
          const Divider(height: 24),
          ..._budgets.map((b) => ListTile(
              title: Text('${b['fund_type']} • ${b['month_key']}'),
              subtitle: Text(
                  'Planned In: ${b['planned_in']} • Planned Out: ${b['planned_out']}'))),
        ]));
  }

  Widget _approvalPanel() {
    return _panel(
        AppLang.t('Approval Workflow', 'Approval Workflow'),
        Column(children: [
          if (_isAdmin) ...[
            TextField(
                controller: _ruleThreshold,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: AppLang.t(
                        'High-value threshold', 'High-value threshold'))),
            const SizedBox(height: 8),
            Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                    onPressed: _saving ? null : _saveRule,
                    icon: const Icon(Icons.rule),
                    label: Text(AppLang.t('Save Rule', 'Save Rule')))),
            const Divider(height: 24),
          ],
          TextField(
              controller: _requestAmount,
              keyboardType: TextInputType.number,
              decoration:
                  InputDecoration(labelText: AppLang.t('Amount', 'Amount'))),
          TextField(
              controller: _requestSummary,
              decoration: InputDecoration(
                  labelText: AppLang.t('Request summary', 'Request summary'))),
          const SizedBox(height: 8),
          Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                  onPressed: _saving ? null : _createRequest,
                  icon: const Icon(Icons.add_task),
                  label: Text(AppLang.t('Create Request', 'Create Request')))),
          const Divider(height: 24),
          ..._approvalRules.map((r) => ListTile(
              title: Text('${r['action_type']}'),
              subtitle: Text(
                  'Threshold: ${r['threshold_amount']} • Active: ${r['active']}'))),
          ..._approvalRequests.map((r) => Card(
              elevation: 0,
              child: ListTile(
                  title: Text(r['summary']?.toString() ?? '-'),
                  subtitle: Text('${r['amount']} • ${r['status']}'),
                  trailing: _isAdmin && r['status'] == 'PENDING'
                      ? Wrap(spacing: 6, children: [
                          IconButton(
                              onPressed: () =>
                                  _decide(r['id'].toString(), 'APPROVED'),
                              icon: const Icon(Icons.check)),
                          IconButton(
                              onPressed: () =>
                                  _decide(r['id'].toString(), 'REJECTED'),
                              icon: const Icon(Icons.close))
                        ])
                      : null))),
        ]));
  }
}
