import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_lang.dart';
import '../../shared/constants/fund_types.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';
import 'donor_broadcast_screen.dart';

String hashDonorPin(String pin) => sha256.convert(utf8.encode(pin.trim())).toString();

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
  List<Map<String, dynamic>> _targets = [];
  bool _loadingPending = true;
  bool _loadingAll = true;
  bool _loadingTxns = true;
  bool _loadingTargets = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _loadAll();
  }

  void _loadAll() {
    _loadPending();
    _loadAllDonors();
    _loadDonorTxns();
    _loadTargets();
  }

  Future<void> _loadTargets({bool forceRefresh = false}) async {
    setState(() => _loadingTargets = true);
    final res = await _api.get('adminListDonationTargets', forceRefresh: forceRefresh);
    if (mounted && res['ok'] == true) {
      final raw = res['data'] as List? ?? [];
      setState(() => _targets = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    }
    if (mounted) setState(() => _loadingTargets = false);
  }

  Future<void> _openRetentionDialog() async {
    final res = await _api.get('getDonorNotifRetentionDays');
    final current = (res['ok'] == true ? res['days'] as num? : null) ?? 30;
    final ctrl = TextEditingController(text: '$current');
    if (!mounted) return;

    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLang.t('বিজ্ঞপ্তি স্বয়ংক্রিয়-মুছার সময়', 'Notification auto-delete period')),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: AppLang.t('দিন সংখ্যা', 'Number of days'),
            helperText: AppLang.t(
              'এর বেশি পুরনো বিজ্ঞপ্তি স্বয়ংক্রিয়ভাবে মুছে যাবে',
              'Notifications older than this are deleted automatically',
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLang.t('বাতিল', 'Cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text.trim()) ?? current.toInt()),
            child: Text(AppLang.t('সংরক্ষণ', 'Save')),
          ),
        ],
      ),
    );
    if (days == null || !mounted) return;

    final saveRes = await _api.post('setDonorNotifRetentionDays', {
      'user_role': SessionService.role,
      'payload': {'days': days},
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(saveRes['ok'] == true
            ? AppLang.t('সংরক্ষিত হয়েছে', 'Saved')
            : (saveRes['message'] as String? ?? AppLang.t('ত্রুটি', 'Error'))),
      ));
    }
  }

  Future<void> _saveTarget(Map<String, dynamic> payload) async {
    final res = await _api.post('setDonationTarget', {
      'payload': payload,
      'user_role': SessionService.role,
      'user_id': SessionService.userId,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['ok'] == true
            ? AppLang.t('সংরক্ষিত হয়েছে', 'Saved')
            : (res['message'] as String? ?? AppLang.t('ত্রুটি', 'Error'))),
      ));
      if (res['ok'] == true) _loadTargets();
    }
  }

  Future<void> _loadPending({bool forceRefresh = false}) async {
    setState(() => _loadingPending = true);
    final res = await _api.get('adminListPendingDonors', forceRefresh: forceRefresh);
    if (mounted && res['ok'] == true) {
      final raw = res['data'] as List? ?? [];
      setState(() => _pending = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    }
    if (mounted) setState(() => _loadingPending = false);
  }

  Future<void> _loadAllDonors({bool forceRefresh = false}) async {
    setState(() => _loadingAll = true);
    final res = await _api.get('adminListAllDonors', forceRefresh: forceRefresh);
    if (mounted && res['ok'] == true) {
      final raw = res['data'] as List? ?? [];
      setState(() => _allDonors = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    }
    if (mounted) setState(() => _loadingAll = false);
  }

  Future<void> _loadDonorTxns({bool forceRefresh = false}) async {
    setState(() => _loadingTxns = true);
    final res = await _api.get('adminListDonorTransactions', forceRefresh: forceRefresh);
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

  Future<void> _resetDonorPin(String donorId, String pinHash) async {
    await _api.post('adminSetDonorPin', {
      'payload': {'donor_id': donorId, 'pin_hash': pinHash},
      'user_role': SessionService.role,
      'user_id': SessionService.userId,
    });
  }

  Future<void> _confirmTxn(String id, String status, [Map<String, dynamic>? extra]) async {
    final res = await _api.post('confirmDonation', {
      'payload': {'id': id, 'status': status, ...?extra},
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
      actions: [
        IconButton(
          icon: const Icon(Icons.campaign_outlined),
          tooltip: AppLang.t('বিজ্ঞপ্তি ও রিমাইন্ডার', 'Notifications & Reminders'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DonorBroadcastScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_active_outlined),
          tooltip: AppLang.t('বিজ্ঞপ্তি স্বয়ংক্রিয়-মুছার সময়', 'Notification auto-delete period'),
          onPressed: _openRetentionDialog,
        ),
      ],
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            tabs: [
              Tab(text: AppLang.t('অনুমোদন (${_pending.length})', 'Approvals (${_pending.length})')),
              Tab(text: AppLang.t('দানকারী', 'Donors')),
              Tab(text: AppLang.t('লেনদেন', 'Transactions')),
              Tab(text: AppLang.t('লক্ষ্যমাত্রা', 'Targets')),
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
                  onRefresh: () => _loadPending(forceRefresh: true),
                ),
                _AllDonorsTab(
                  donors: _allDonors,
                  loading: _loadingAll,
                  onRefresh: () => _loadAllDonors(forceRefresh: true),
                  onResetPin: _resetDonorPin,
                ),
                _TxnsTab(
                  txns: _donorTxns,
                  loading: _loadingTxns,
                  onConfirm: (id, extra) => _confirmTxn(id, 'CONFIRMED', extra),
                  onReject: (id) => _confirmTxn(id, 'REJECTED'),
                  onRefresh: () => _loadDonorTxns(forceRefresh: true),
                ),
                _TargetsTab(
                  targets: _targets,
                  loading: _loadingTargets,
                  onSave: _saveTarget,
                  onRefresh: () => _loadTargets(forceRefresh: true),
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
  final Future<void> Function(String donorId, String pinHash) onResetPin;
  const _AllDonorsTab({
    required this.donors, required this.loading, required this.onRefresh,
    required this.onResetPin,
  });

  Future<void> _openResetPinDialog(BuildContext context, Map<String, dynamic> d) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLang.t('পিন রিসেট করুন', 'Reset PIN')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${d['name_bn']} (${d['phone']})'),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(labelText: AppLang.t('নতুন পিন (৪-৬ সংখ্যা)', 'New PIN (4-6 digits)')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLang.t('বাতিল', 'Cancel'))),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.length < 4) return;
              Navigator.pop(ctx, v);
            },
            child: Text(AppLang.t('সংরক্ষণ', 'Save')),
          ),
        ],
      ),
    );
    if (confirmed == null) return;
    await onResetPin(d['id'] as String, hashDonorPin(confirmed));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLang.t('পিন রিসেট হয়েছে', 'PIN reset')),
      ));
    }
  }

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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusChip(d['status'] as String? ?? ''),
                  IconButton(
                    icon: const Icon(Icons.lock_reset, size: 20),
                    tooltip: AppLang.t('পিন রিসেট', 'Reset PIN'),
                    onPressed: () => _openResetPinDialog(context, d),
                  ),
                ],
              ),
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
  final void Function(String id, Map<String, dynamic> extra) onConfirm;
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
          final isForeign = (t['currency'] as String?) != 'BDT';
          final ft = FundTypes.byKey(t['fund_type'] as String?);
          final titleAmount = (isPending && isForeign)
              ? '${t['amount_foreign']} ${t['currency']}'
              : '৳${t['amount_bdt']}';
          return Card(
            child: ExpansionTile(
              leading: _StatusChip(t['status'] as String? ?? ''),
              title: Text(
                '${t['donor_name_bn'] ?? ''}  •  $titleAmount',
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
                      if (isForeign && !isPending)
                        Text('${t['amount_foreign']} ${t['currency']}  @ ৳${t['exchange_rate']}'),
                      if (isForeign && isPending)
                        Text(AppLang.t(
                          'BDT-তে কত জমা হয়েছে নিশ্চিত করার সময় লিখুন',
                          'Enter the BDT amount received when confirming',
                        )),
                      if (!isPending && (_toNum(t['transfer_charge_bdt']) > 0))
                        Text(AppLang.t(
                          'চার্জ: ৳${t['transfer_charge_bdt']}  •  মাদ্রাসা পেয়েছে: ৳${t['net_amount_bdt']}',
                          'Charge: ৳${t['transfer_charge_bdt']}  •  Madrasah received: ৳${t['net_amount_bdt']}',
                        )),
                      Text('${AppLang.t('পদ্ধতি', 'Method')}: ${t['payment_method'] ?? ''}'),
                      if ((t['txn_reference'] as String?)?.isNotEmpty ?? false)
                        Text('Ref: ${t['txn_reference']}'),
                      if ((t['slip_url'] as String?)?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: GestureDetector(
                            onTap: () => launchUrl(Uri.parse(t['slip_url'] as String),
                                mode: LaunchMode.externalApplication),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    t['slip_url'] as String,
                                    width: 56, height: 56, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(AppLang.t('স্লিপ দেখুন', 'View slip'),
                                    style: const TextStyle(decoration: TextDecoration.underline)),
                              ],
                            ),
                          ),
                        ),
                      if ((t['notes'] as String?)?.isNotEmpty ?? false)
                        Text('${AppLang.t('নোট', 'Note')}: ${t['notes']}'),
                      if (isPending) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _openConfirmDialog(context, t, isForeign),
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

  Future<void> _openConfirmDialog(BuildContext context, Map<String, dynamic> t, bool isForeign) async {
    final receivedCtrl = TextEditingController();
    final chargeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLang.t('দান নিশ্চিত করুন', 'Confirm Donation')),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isForeign) ...[
                Text(AppLang.t(
                  'দানকারী পাঠিয়েছেন: ${t['amount_foreign']} ${t['currency']}',
                  'Donor sent: ${t['amount_foreign']} ${t['currency']}',
                )),
                const SizedBox(height: 10),
                TextFormField(
                  controller: receivedCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: AppLang.t('প্রাপ্ত পরিমাণ (৳) *', 'Received Amount (৳) *')),
                  validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                      ? AppLang.t('পরিমাণ দিন', 'Enter amount') : null,
                ),
                const SizedBox(height: 10),
              ],
              TextFormField(
                controller: chargeCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppLang.t('ব্যাংক/বিকাশ চার্জ (ঐচ্ছিক)', 'Bank/bKash Charge (optional)'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLang.t('বাতিল', 'Cancel'))),
          FilledButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(ctx, true);
            },
            child: Text(AppLang.t('নিশ্চিত করুন', 'Confirm')),
          ),
        ],
      ),
    );

    if (result == true) {
      onConfirm(t['id'] as String, {
        if (isForeign) 'received_amount_bdt': double.tryParse(receivedCtrl.text.trim()) ?? 0,
        'transfer_charge_bdt': double.tryParse(chargeCtrl.text.trim()) ?? 0,
      });
    }
  }

  String _date(dynamic v) {
    final s = (v as String?) ?? '';
    return s.length >= 10 ? s.substring(0, 10) : s;
  }
}

// ── Donation targets ─────────────────────────────────────────────────────────

class _TargetsTab extends StatelessWidget {
  final List<Map<String, dynamic>> targets;
  final bool loading;
  final void Function(Map<String, dynamic>) onSave;
  final VoidCallback onRefresh;
  const _TargetsTab({
    required this.targets, required this.loading,
    required this.onSave, required this.onRefresh,
  });

  Map<String, dynamic>? _findTarget(String fundKey) {
    for (final t in targets) {
      if (t['fund_type'] == fundKey) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: FundTypes.all.length,
        itemBuilder: (_, i) {
          final ft = FundTypes.all[i];
          final t = _findTarget(ft.key);
          final isActive = t == null ? false : (t['is_active'] == true || t['is_active'] == 'TRUE' || t['is_active'] == '1');
          final target = _toNum(t?['target_amount']);
          final collected = _toNum(t?['collected_amount']);
          return Card(
            child: ListTile(
              title: Text(AppLang.isEnglish.value ? ft.labelEn : ft.labelBn),
              subtitle: target > 0
                  ? Text(AppLang.t(
                      'লক্ষ্য: ৳$target  •  সংগৃহীত: ৳$collected',
                      'Target: ৳$target  •  Collected: ৳$collected',
                    ))
                  : Text(AppLang.t('কোনো লক্ষ্য সেট করা নেই', 'No target set')),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (t != null)
                    Icon(isActive ? Icons.visibility : Icons.visibility_off,
                        size: 18, color: isActive ? Colors.green : Colors.grey),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit, size: 18),
                ],
              ),
              onTap: () => _openEditDialog(context, ft, t),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context, FundType ft, Map<String, dynamic>? existing) async {
    final titleBn = TextEditingController(text: existing?['title_bn'] as String? ?? ft.labelBn);
    final titleEn = TextEditingController(text: existing?['title_en'] as String? ?? ft.labelEn);
    final amount = TextEditingController(text: existing?['target_amount'] != null ? '${existing!['target_amount']}' : '');
    final desc = TextEditingController(text: existing?['description_bn'] as String? ?? ft.descBn);
    bool active = existing == null ? true : (existing['is_active'] == true || existing['is_active'] == 'TRUE' || existing['is_active'] == '1');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(AppLang.isEnglish.value ? ft.labelEn : ft.labelBn),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleBn, decoration: InputDecoration(labelText: AppLang.t('শিরোনাম (বাংলা)', 'Title (Bangla)'))),
                const SizedBox(height: 8),
                TextField(controller: titleEn, decoration: InputDecoration(labelText: AppLang.t('শিরোনাম (ইংরেজি)', 'Title (English)'))),
                const SizedBox(height: 8),
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: AppLang.t('লক্ষ্য পরিমাণ (৳)', 'Target Amount (৳)')),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: desc,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: AppLang.t('বিবরণ', 'Description')),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppLang.t('দানকারী পোর্টালে দৃশ্যমান', 'Visible on donor portal')),
                  value: active,
                  onChanged: (v) => setD(() => active = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLang.t('বাতিল', 'Cancel'))),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {
                'fund_type': ft.key,
                'title_bn': titleBn.text.trim(),
                'title_en': titleEn.text.trim(),
                'target_amount': double.tryParse(amount.text.trim()) ?? 0,
                'description_bn': desc.text.trim(),
                'is_active': active,
              }),
              child: Text(AppLang.t('সংরক্ষণ', 'Save')),
            ),
          ],
        ),
      ),
    );
    if (result != null) onSave(result);
  }
}

num _toNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
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
