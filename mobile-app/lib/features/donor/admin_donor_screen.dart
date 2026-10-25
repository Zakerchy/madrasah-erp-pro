import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../shared/constants/fund_types.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';

class AdminDonorScreen extends StatefulWidget {
  const AdminDonorScreen({super.key});

  @override
  State<AdminDonorScreen> createState() => _AdminDonorScreenState();
}

class _AdminDonorScreenState extends State<AdminDonorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _api = ApiService();

  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _allDonors = [];
  List<Map<String, dynamic>> _donorTxns = [];
  bool _loadingPending = true;
  bool _loadingAll = true;
  bool _loadingTxns = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadAll();
  }

  void _loadAll() {
    _loadPending();
    _loadAllDonors();
    _loadDonorTxns();
  }

  Future<void> _loadPending() async {
    setState(() => _loadingPending = true);
    final res = await _api.get('adminListPendingDonors');
    if (mounted && res['ok'] == true) {
      final raw = res['data'] as List? ?? [];
      setState(() => _pending = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    }
    if (mounted) setState(() => _loadingPending = false);
  }

  Future<void> _loadAllDonors() async {
    setState(() => _loadingAll = true);
    final res = await _api.get('adminListAllDonors');
    if (mounted && res['ok'] == true) {
      final raw = res['data'] as List? ?? [];
      setState(() => _allDonors = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    }
    if (mounted) setState(() => _loadingAll = false);
  }

  Future<void> _loadDonorTxns() async {
    setState(() => _loadingTxns = true);
    final res = await _api.get('adminListDonorTransactions');
    if (mounted && res['ok'] == true) {
      final raw = res['data'] as List? ?? [];
      setState(() => _donorTxns = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    }
    if (mounted) setState(() => _loadingTxns = false);
  }

  Future<void> _approve(String id, String status) async {
    final res = await _api.post('approveDonor', {
      'payload': {'id': id, 'status': status},
      'user_role': SessionService.role,
      'user_id': SessionService.userId,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['ok'] == true
            ? AppLang.t('সম্পন্ন', 'Done')
            : (res['message'] as String? ?? AppLang.t('ত্রুটি', 'Error'))),
      ));
      _loadPending();
      _loadAllDonors();
    }
  }

  Future<void> _confirmTxn(String id, String status) async {
    final res = await _api.post('confirmDonation', {
      'payload': {'id': id, 'status': status},
      'user_role': SessionService.role,
      'user_id': SessionService.userId,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['ok'] == true
            ? AppLang.t('নিশ্চিত হয়েছে', 'Confirmed')
            : (res['message'] as String? ?? AppLang.t('ত্রুটি', 'Error'))),
      ));
      _loadDonorTxns();
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: AppLang.t('দানকারী ব্যবস্থাপনা', 'Donor Management'),
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            tabs: [
              Tab(text: AppLang.t('অনুমোদন (${_pending.length})', 'Approvals (${_pending.length})')),
              Tab(text: AppLang.t('দানকারী', 'Donors')),
              Tab(text: AppLang.t('লেনদেন', 'Transactions')),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _PendingTab(
                  donors: _pending,
                  loading: _loadingPending,
                  onApprove: (id) => _approve(id, 'ACTIVE'),
                  onReject: (id) => _approve(id, 'REJECTED'),
                  onRefresh: _loadPending,
                ),
                _AllDonorsTab(donors: _allDonors, loading: _loadingAll, onRefresh: _loadAllDonors),
                _TxnsTab(
                  txns: _donorTxns,
                  loading: _loadingTxns,
                  onConfirm: (id) => _confirmTxn(id, 'CONFIRMED'),
                  onReject: (id) => _confirmTxn(id, 'REJECTED'),
                  onRefresh: _loadDonorTxns,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending approvals ────────────────────────────────────────────────────────

class _PendingTab extends StatelessWidget {
  final List<Map<String, dynamic>> donors;
  final bool loading;
  final void Function(String) onApprove;
  final void Function(String) onReject;
  final VoidCallback onRefresh;
  const _PendingTab({
    required this.donors, required this.loading,
    required this.onApprove, required this.onReject, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (donors.isEmpty) return Center(child: Text(AppLang.t('কোনো মুলতুবি নেই', 'No pending approvals')));
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: donors.length,
        itemBuilder: (_, i) {
          final d = donors[i];
          return Card(
            child: ListTile(
              title: Text('${d['name_bn']} (${d['phone']})'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((d['profession'] as String?)?.isNotEmpty ?? false)
                    Text('${d['profession']} • ${d['city'] ?? ''} • ${d['country'] ?? ''}'),
                  Text('${AppLang.t('নিবন্ধন', 'Reg')}: ${_date(d['created_at'])}'),
                ],
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    tooltip: AppLang.t('অনুমোদন', 'Approve'),
                    onPressed: () => onApprove(d['id'] as String),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    tooltip: AppLang.t('বাতিল', 'Reject'),
                    onPressed: () => onReject(d['id'] as String),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _date(dynamic v) {
    final s = (v as String?) ?? '';
    return s.length >= 10 ? s.substring(0, 10) : s;
  }
}

// ── All donors ───────────────────────────────────────────────────────────────

class _AllDonorsTab extends StatelessWidget {
  final List<Map<String, dynamic>> donors;
  final bool loading;
  final VoidCallback onRefresh;
  const _AllDonorsTab({required this.donors, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (donors.isEmpty) return Center(child: Text(AppLang.t('কোনো দানকারী নেই', 'No donors')));
    final active = donors.where((d) => d['status'] == 'ACTIVE').length;
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              AppLang.t('মোট: ${donors.length}  সক্রিয়: $active', 'Total: ${donors.length}  Active: $active'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...donors.map((d) => Card(
            child: ListTile(
              leading: CircleAvatar(child: Text((d['name_bn'] as String? ?? '?')[0])),
              title: Text('${d['name_bn']}  (${d['phone']})'),
              subtitle: Text('${d['country'] ?? ''} • ${d['currency_pref'] ?? 'BDT'} • ${d['status']}'),
              trailing: _StatusChip(d['status'] as String? ?? ''),
            ),
          )),
        ],
      ),
    );
  }
}

// ── Donor transactions ───────────────────────────────────────────────────────

class _TxnsTab extends StatelessWidget {
  final List<Map<String, dynamic>> txns;
  final bool loading;
  final void Function(String) onConfirm;
  final void Function(String) onReject;
  final VoidCallback onRefresh;
  const _TxnsTab({
    required this.txns, required this.loading,
    required this.onConfirm, required this.onReject, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (txns.isEmpty) return Center(child: Text(AppLang.t('কোনো লেনদেন নেই', 'No transactions')));
    final pending = txns.where((t) => t['status'] == 'PENDING').toList();
    final rest = txns.where((t) => t['status'] != 'PENDING').toList();
    final all = [...pending, ...rest];
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: all.length,
        itemBuilder: (_, i) {
          final t = all[i];
          final isPending = t['status'] == 'PENDING';
          final ft = FundTypes.byKey(t['fund_type'] as String?);
          return Card(
            child: ExpansionTile(
              leading: _StatusChip(t['status'] as String? ?? ''),
              title: Text(
                '${t['donor_name_bn'] ?? ''}  •  ৳${t['amount_bdt']}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${AppLang.isEnglish.value ? (ft?.labelEn ?? t['fund_type']) : (ft?.labelBn ?? t['fund_type'])}  •  ${_date(t['created_at'])}',
                style: const TextStyle(fontSize: 12),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if ((t['currency'] as String?) != 'BDT')
                        Text('${t['amount_foreign']} ${t['currency']}  @ ${t['exchange_rate']}'),
                      Text('${AppLang.t('পদ্ধতি', 'Method')}: ${t['payment_method'] ?? ''}'),
                      if ((t['txn_reference'] as String?)?.isNotEmpty ?? false)
                        Text('Ref: ${t['txn_reference']}'),
                      if ((t['notes'] as String?)?.isNotEmpty ?? false)
                        Text('${AppLang.t('নোট', 'Note')}: ${t['notes']}'),
                      if (isPending) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => onConfirm(t['id'] as String),
                                icon: const Icon(Icons.check, size: 16),
                                label: Text(AppLang.t('নিশ্চিত করুন', 'Confirm')),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => onReject(t['id'] as String),
                                icon: const Icon(Icons.close, size: 16),
                                label: Text(AppLang.t('বাতিল', 'Reject')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _date(dynamic v) {
    final s = (v as String?) ?? '';
    return s.length >= 10 ? s.substring(0, 10) : s;
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    switch (status) {
      case 'ACTIVE':
      case 'CONFIRMED': bg = Colors.green; label = status == 'ACTIVE' ? AppLang.t('সক্রিয়', 'Active') : AppLang.t('নিশ্চিত', 'Confirmed'); break;
      case 'REJECTED': bg = Colors.red; label = AppLang.t('বাতিল', 'Rejected'); break;
      case 'PENDING': bg = Colors.orange; label = AppLang.t('অপেক্ষামাণ', 'Pending'); break;
      default: bg = Colors.grey; label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, color: bg, fontWeight: FontWeight.bold)),
    );
  }
}
