import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../shared/constants/fund_types.dart';
import '../../shared/widgets/donation_invoice_screen.dart';
import 'donor_api.dart';
import 'donor_session.dart';

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});

  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _txns = [];
  bool _loadingSummary = true;
  bool _loadingTxns = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadSummary();
    _loadTxns();
  }

  Future<void> _loadSummary() async {
    setState(() => _loadingSummary = true);
    try {
      final res = await DonorApi.myDashboard(DonorSession.donorId!, DonorSession.donorToken!);
      if (res['ok'] == true) setState(() => _summary = res);
    } finally {
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  Future<void> _loadTxns() async {
    setState(() => _loadingTxns = true);
    try {
      final res = await DonorApi.myTransactions(DonorSession.donorId!, DonorSession.donorToken!);
      if (res['ok'] == true) {
        final raw = res['data'] as List? ?? [];
        setState(() => _txns = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
    } finally {
      if (mounted) setState(() => _loadingTxns = false);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLang.t('আমার দান', 'My Donations')),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: AppLang.t('সারসংক্ষেপ', 'Summary')),
            Tab(text: AppLang.t('লেজার', 'Ledger')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _SummaryTab(summary: _summary, loading: _loadingSummary, onRefresh: _loadSummary),
          _LedgerTab(txns: _txns, loading: _loadingTxns, onRefresh: _loadTxns),
        ],
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final Map<String, dynamic>? summary;
  final bool loading;
  final VoidCallback onRefresh;
  const _SummaryTab({required this.summary, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (loading) return const Center(child: CircularProgressIndicator());
    if (summary == null) {
      return Center(
        child: TextButton(onPressed: onRefresh, child: Text(AppLang.t('আবার চেষ্টা', 'Retry'))),
      );
    }

    final s = summary!['summary'] as Map? ?? {};
    final byFund = (summary!['by_fund'] as Map? ?? {}).map(
      (k, v) => MapEntry(k as String, (v as num).toDouble()),
    );

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cards
          Row(
            children: [
              _StatCard(
                label: AppLang.t('মোট দান', 'Total Donated'),
                value: '৳ ${_fmt(s['total_donated_bdt'])}',
                icon: Icons.favorite,
                color: cs.primary,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: AppLang.t('ব্যয় হয়েছে', 'Used'),
                value: '৳ ${_fmt(s['total_used_bdt'])}',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatCard(
                label: AppLang.t('অবশিষ্ট', 'Balance'),
                value: '৳ ${_fmt(s['balance_bdt'])}',
                icon: Icons.account_balance_wallet,
                color: cs.secondary,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: AppLang.t('অপেক্ষামাণ', 'Pending'),
                value: '${s['pending_count'] ?? 0}টি',
                icon: Icons.hourglass_bottom,
                color: Colors.orange,
              ),
            ],
          ),
          if ((s['total_charge_bdt'] as num? ?? 0) > 0) ...[
            const SizedBox(height: 10),
            Text(
              AppLang.t(
                'ব্যাংক/বিকাশ চার্জ বাবদ মোট ৳${_fmt(s['total_charge_bdt'])} কাটা হয়েছে',
                'Total ৳${_fmt(s['total_charge_bdt'])} deducted as bank/bKash charges',
              ),
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 16),

          // Fund breakdown
          if (byFund.isNotEmpty) ...[
            Text(AppLang.t('খাতভিত্তিক দান', 'Fund-wise Donations'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...byFund.entries.map((e) {
              final ft = FundTypes.byKey(e.key);
              return ListTile(
                dense: true,
                leading: const Icon(Icons.circle, size: 10),
                title: Text(AppLang.isEnglish.value ? (ft?.labelEn ?? e.key) : (ft?.labelBn ?? e.key)),
                trailing: Text('৳ ${_fmt(e.value)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ],
      ),
    );
  }

  String _fmt(dynamic v) {
    final d = (v as num?)?.toDouble() ?? 0;
    if (d >= 100000) return '${(d / 100000).toStringAsFixed(1)}L';
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(1)}K';
    return d.toStringAsFixed(0);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerTab extends StatelessWidget {
  final List<Map<String, dynamic>> txns;
  final bool loading;
  final VoidCallback onRefresh;
  const _LedgerTab({required this.txns, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (loading) return const Center(child: CircularProgressIndicator());
    if (txns.isEmpty) return Center(child: Text(AppLang.t('কোনো দান নেই', 'No donations yet')));

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: txns.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final t = txns[i];
          final status = t['status'] as String? ?? '';
          final ft = FundTypes.byKey(t['fund_type'] as String?);
          final confirmed = status == 'CONFIRMED';
          final pending = status == 'PENDING';

          return ExpansionTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: confirmed
                  ? Colors.green.withValues(alpha: 0.15)
                  : pending
                      ? Colors.orange.withValues(alpha: 0.15)
                      : cs.errorContainer,
              child: Icon(
                confirmed ? Icons.check : pending ? Icons.hourglass_bottom : Icons.close,
                color: confirmed ? Colors.green : pending ? Colors.orange : cs.error,
                size: 18,
              ),
            ),
            title: Text(
              AppLang.isEnglish.value ? (ft?.labelEn ?? (t['fund_type'] as String? ?? '')) : (ft?.labelBn ?? (t['fund_type'] as String? ?? '')),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              '${pending && (t['currency'] as String?) != 'BDT' ? '${t['amount_foreign']} ${t['currency']}' : '৳ ${t['amount_bdt']}'}  •  ${_formatDate(t['created_at'])}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: _StatusChip(status),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((t['currency'] as String?) != 'BDT' && (t['amount_foreign'] as num?) != null)
                      _row(AppLang.t('বিদেশী মুদ্রা', 'Foreign Amount'),
                        confirmed
                            ? '${t['amount_foreign']} ${t['currency']}  (রেট: ${t['exchange_rate']})'
                            : '${t['amount_foreign']} ${t['currency']}'),
                    _row(AppLang.t('পদ্ধতি', 'Method'), _methodLabel(t['payment_method'] as String?)),
                    if ((t['txn_reference'] as String?)?.isNotEmpty ?? false)
                      _row(AppLang.t('রেফারেন্স', 'Reference'), t['txn_reference'] as String),
                    if ((t['notes'] as String?)?.isNotEmpty ?? false)
                      _row(AppLang.t('নোট', 'Note'), t['notes'] as String),
                    if (confirmed && (t['confirmed_at'] as String?)?.isNotEmpty == true)
                      _row(AppLang.t('নিশ্চিত', 'Confirmed'), _formatDate(t['confirmed_at'])),
                    if (confirmed && (t['transfer_charge_bdt'] as num? ?? 0) > 0) ...[
                      _row(AppLang.t('ব্যাংক/বিকাশ চার্জ', 'Bank/bKash Charge'), '৳ ${t['transfer_charge_bdt']}'),
                      _row(AppLang.t('মাদ্রাসা পেয়েছে', 'Madrasah Received'), '৳ ${t['net_amount_bdt']}'),
                    ],
                    // Linked expenses
                    if ((t['expense_links'] as List?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(AppLang.t('কোথায় ব্যয় হয়েছে:', 'Where used:'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ...((t['expense_links'] as List).map((l) {
                        final m = Map<String, dynamic>.from(l as Map);
                        return Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Text('• ৳ ${m['amount_used']}  ${m['notes'] ?? ''}',
                            style: const TextStyle(fontSize: 12)),
                        );
                      })),
                    ],
                    if (confirmed) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => DonationInvoiceScreen(
                              txn: t,
                              donorName: DonorSession.nameBn,
                              donorPhone: DonorSession.phone,
                            ),
                          )),
                          icon: const Icon(Icons.receipt_long_outlined, size: 16),
                          label: Text(AppLang.t('রশিদ দেখুন', 'View Receipt')),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Row(
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );

  String _formatDate(dynamic v) {
    final s = (v as String?) ?? '';
    if (s.length >= 10) return s.substring(0, 10);
    return s;
  }

  String _methodLabel(String? m) {
    const map = {
      'CASH': 'নগদ', 'BANK_TRANSFER': 'ব্যাংক ট্রান্সফার',
      'MOBILE_BANKING': 'মোবাইল ব্যাংকিং', 'CHEQUE': 'চেক', 'OTHER': 'অন্যান্য',
    };
    return map[m] ?? (m ?? '');
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
      case 'CONFIRMED': bg = Colors.green; label = AppLang.t('নিশ্চিত', 'Confirmed'); break;
      case 'REJECTED': bg = Colors.red; label = AppLang.t('বাতিল', 'Rejected'); break;
      default: bg = Colors.orange; label = AppLang.t('অপেক্ষামাণ', 'Pending');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, color: bg, fontWeight: FontWeight.bold)),
    );
  }
}
