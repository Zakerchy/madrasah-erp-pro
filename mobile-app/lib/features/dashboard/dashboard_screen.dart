import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../shared/models/dashboard_summary.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import 'fund_detail_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  bool _loading = true;
  bool _offline = false;
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
        _summary = DashboardSummary.fromMap((res['data'] ?? {}) as Map<String, dynamic>);
        _offline = res['offline'] == true;
      } else {
        _error = (res['message'] ?? res['error'] ?? 'তথ্য লোড ব্যর্থ').toString();
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
        const SnackBar(content: Text('বের হতে আবার চাপুন')),
      );
      return false;
    }
    return true;
  }

  String _fmt(double n) {
    if (n >= 10000000) return '৳${(n / 10000000).toStringAsFixed(1)}কোটি';
    if (n >= 100000) return '৳${(n / 100000).toStringAsFixed(1)}লাখ';
    return '৳${NumberFormat('#,##0', 'en_US').format(n.toInt())}';
  }

  void _goToFund(String fundKey, String fundName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FundDetailPage(fundKey: fundKey, fundName: fundName),
      ),
    );
  }

  Future<void> _quickEntry({required bool income}) async {
    final formKey = GlobalKey<FormState>();
    final dateCtrl = TextEditingController(
        text: DateTime.now().toIso8601String().split('T').first);
    final amountCtrl = TextEditingController();
    final sourceCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var fundType = 'CONSTRUCTION';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(income ? '+ দান / আয়' : '+ ব্যয়'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: dateCtrl,
                    decoration: const InputDecoration(labelText: 'তারিখ (YYYY-MM-DD)'),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'দিন' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: fundType,
                    decoration: const InputDecoration(labelText: 'ফান্ড'),
                    items: const [
                      DropdownMenuItem(value: 'CONSTRUCTION', child: Text('নির্মাণ ফান্ড')),
                      DropdownMenuItem(value: 'JAKAT', child: Text('যাকাত ফান্ড')),
                      DropdownMenuItem(value: 'SCHOLARSHIP', child: Text('বৃত্তি ফান্ড')),
                      DropdownMenuItem(value: 'GENERAL', child: Text('সাদাকাহ / সাধারণ')),
                    ],
                    onChanged: (v) => setD(() => fundType = v ?? 'CONSTRUCTION'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'পরিমাণ (৳)'),
                    validator: (v) {
                      final n = double.tryParse(v?.trim() ?? '') ?? 0;
                      return n <= 0 ? 'সঠিক পরিমাণ দিন' : null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: sourceCtrl,
                    decoration: InputDecoration(
                        labelText: income ? 'দাতার নাম' : 'কোথায় খরচ'),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'দিন' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: noteCtrl,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'নোট (ঐচ্ছিক)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('বাতিল')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('সংরক্ষণ'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final res = await _api.post('createTransaction', {
      'user_role': SessionService.role,
      'payload': {
        'txn_date': dateCtrl.text.trim(),
        'direction': income ? 'IN' : 'OUT',
        'fund_type': fundType,
        'amount': double.tryParse(amountCtrl.text.trim()) ?? 0,
        'source_or_vendor': sourceCtrl.text.trim(),
        'category': income ? 'DONATION' : 'EXPENSE',
        'notes': noteCtrl.text.trim(),
        'created_by': SessionService.userId,
      },
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message'] ?? (res['ok'] == true ? 'সংরক্ষিত হয়েছে' : 'ব্যর্থ হয়েছে')),
        backgroundColor: res['ok'] == true ? Colors.green : Colors.red,
      ),
    );
    if (res['ok'] == true && res['queued'] != true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (SessionService.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FDF4),
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          title: const Text('মাদ্রাসা ERP', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            if (_offline)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.cloud_off, size: 18),
              ),
            IconButton(
              onPressed: _load,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.refresh),
              tooltip: 'রিফ্রেশ',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu),
              onSelected: (v) {
                switch (v) {
                  case 'salary':
                    Navigator.pushNamed(context, '/salary');
                  case 'scholarship':
                    Navigator.pushNamed(context, '/scholarship');
                  case 'beneficiaries':
                    Navigator.pushNamed(context, '/beneficiaries');
                  case 'reports':
                    Navigator.pushNamed(context, '/reports');
                  case 'settings':
                    Navigator.pushNamed(context, '/settings');
                  case 'logout':
                    SessionService.clear();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'salary', child: Text('বেতন')),
                const PopupMenuItem(value: 'scholarship', child: Text('বৃত্তি')),
                const PopupMenuItem(value: 'beneficiaries', child: Text('উপকারভোগী')),
                const PopupMenuItem(value: 'reports', child: Text('রিপোর্ট')),
                if (SessionService.role == 'ADMIN')
                  const PopupMenuItem(value: 'settings', child: Text('সেটিংস')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'logout', child: Text('লগআউট')),
              ],
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorView(error: _error!, onRetry: _load)
                : _buildBody(),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'expense',
              onPressed: () => _quickEntry(income: false),
              backgroundColor: Colors.red.shade600,
              tooltip: 'ব্যয় যোগ করুন',
              child: const Icon(Icons.remove, color: Colors.white),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'income',
              onPressed: () => _quickEntry(income: true),
              tooltip: 'দান / আয় যোগ করুন',
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final s = _summary;
    if (s == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('কোনো তথ্য নেই'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('পুনরায় চেষ্টা করুন')),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // Greeting
        _GreetingCard(),
        const SizedBox(height: 12),

        // Total Found — big summary card
        _TotalSummaryCard(summary: s, fmt: _fmt),
        const SizedBox(height: 12),

        // Fund cards 2×2 grid
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('ফান্ড অনুযায়ী বিবরণ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: [
            _FundCard(
              name: 'নির্মাণ ফান্ড',
              icon: Icons.construction,
              color: const Color(0xFF1D4ED8),
              fund: s.fund('CONSTRUCTION'),
              fmt: _fmt,
              onTap: () => _goToFund('CONSTRUCTION', 'নির্মাণ ফান্ড'),
            ),
            _FundCard(
              name: 'যাকাত ফান্ড',
              icon: Icons.volunteer_activism,
              color: const Color(0xFF15803D),
              fund: s.fund('JAKAT'),
              fmt: _fmt,
              onTap: () => _goToFund('JAKAT', 'যাকাত ফান্ড'),
            ),
            _FundCard(
              name: 'বৃত্তি ফান্ড',
              icon: Icons.school,
              color: const Color(0xFF7C3AED),
              fund: s.fund('SCHOLARSHIP'),
              fmt: _fmt,
              onTap: () => _goToFund('SCHOLARSHIP', 'বৃত্তি ফান্ড'),
            ),
            _FundCard(
              name: 'সাদাকাহ / সাধারণ',
              icon: Icons.favorite,
              color: const Color(0xFFB45309),
              fund: s.fund('GENERAL'),
              fmt: _fmt,
              onTap: () => _goToFund('GENERAL', 'সাদাকাহ / সাধারণ'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Separation calculation section
        _SeparationCard(summary: s, fmt: _fmt, onTap: _goToFund),
      ],
    );
  }
}

// ─── Greeting Card ──────────────────────────────────────────────────────────

class _GreetingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                (SessionService.userName.isNotEmpty
                    ? SessionService.userName[0].toUpperCase()
                    : 'A'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('আস-সালামু আলাইকুম, ${SessionService.userName}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('ভূমিকা: ${_roleLabel(SessionService.role)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'ADMIN':
        return 'অ্যাডমিন';
      case 'ACCOUNTANT':
        return 'হিসাবরক্ষক';
      case 'FIELD_USER':
        return 'ফিল্ড ব্যবহারকারী';
      default:
        return 'দর্শক';
    }
  }
}

// ─── Total Summary Card ──────────────────────────────────────────────────────

class _TotalSummaryCard extends StatelessWidget {
  final DashboardSummary summary;
  final String Function(double) fmt;

  const _TotalSummaryCard({required this.summary, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final teal = Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 2,
      color: teal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('মোট সংগ্রহ',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              fmt(summary.totalIn),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _SummaryChip(
                  icon: Icons.arrow_upward,
                  label: 'মোট আয়',
                  value: fmt(summary.totalIn),
                  color: Colors.greenAccent,
                ),
                const SizedBox(width: 12),
                _SummaryChip(
                  icon: Icons.arrow_downward,
                  label: 'মোট ব্যয়',
                  value: fmt(summary.totalOut),
                  color: Colors.redAccent.shade100,
                ),
                const SizedBox(width: 12),
                _SummaryChip(
                  icon: Icons.account_balance_wallet,
                  label: 'ব্যালেন্স',
                  value: fmt(summary.balance),
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryChip(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ]),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

// ─── Fund Card ───────────────────────────────────────────────────────────────

class _FundCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final FundSummary fund;
  final String Function(double) fmt;
  final VoidCallback onTap;

  const _FundCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.fund,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5), size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text('সংগ্রহ',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            Text(fmt(fund.incoming),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ব্যয়',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    Text(fmt(fund.outgoing),
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('ব্যালেন্স',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    Text(
                      fmt(fund.balance),
                      style: TextStyle(
                          fontSize: 12,
                          color: fund.balance >= 0 ? color : Colors.red.shade700,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Separation Calculation Card ─────────────────────────────────────────────

class _SeparationCard extends StatelessWidget {
  final DashboardSummary summary;
  final String Function(double) fmt;
  final void Function(String, String) onTap;

  const _SeparationCard(
      {required this.summary, required this.fmt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final zakatIn = summary.fund('JAKAT').incoming;
    final scholarshipIn = summary.fund('SCHOLARSHIP').incoming;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calculate_outlined, size: 18, color: Color(0xFF0F766E)),
                SizedBox(width: 8),
                Text('ফান্ড পৃথকীকরণ হিসাব',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const Divider(height: 20),
            _SepRow(
              label: 'মোট সংগ্রহ',
              value: fmt(summary.totalIn),
              isTotal: true,
            ),
            _SepRow(
              label: '(−) যাকাত',
              value: '−${fmt(zakatIn)}',
              sublabel: 'আলাদা ফান্ড',
              color: Colors.green.shade700,
              onTap: () => onTap('JAKAT', 'যাকাত ফান্ড'),
            ),
            _SepRow(
              label: 'যাকাত বাদে মোট',
              value: fmt(summary.balanceExclZakat),
              isSubtotal: true,
              onTap: () => onTap('CONSTRUCTION', 'নির্মাণ ফান্ড'),
            ),
            _SepRow(
              label: '(−) বৃত্তি',
              value: '−${fmt(scholarshipIn)}',
              sublabel: 'আলাদা ফান্ড',
              color: Colors.purple.shade700,
              onTap: () => onTap('SCHOLARSHIP', 'বৃত্তি ফান্ড'),
            ),
            _SepRow(
              label: 'যাকাত ও বৃত্তি বাদে',
              value: fmt(summary.balanceExclZakatScholarship),
              isSubtotal: true,
              isLast: true,
            ),
            const SizedBox(height: 4),
            Text(
              '← ডান দিকের তীর চিহ্নে চাপলে বিস্তারিত দেখতে পারবেন',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _SepRow extends StatelessWidget {
  final String label;
  final String value;
  final String? sublabel;
  final Color? color;
  final bool isTotal;
  final bool isSubtotal;
  final bool isLast;
  final VoidCallback? onTap;

  const _SepRow({
    required this.label,
    required this.value,
    this.sublabel,
    this.color,
    this.isTotal = false,
    this.isSubtotal = false,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: isTotal ? 14 : 13,
      fontWeight: isTotal || isSubtotal ? FontWeight.bold : FontWeight.normal,
      color: color ?? (isTotal ? Colors.black87 : Colors.grey.shade800),
    );
    final valueStyle = TextStyle(
      fontSize: isTotal ? 15 : 13,
      fontWeight: FontWeight.bold,
      color: color ?? (isSubtotal ? const Color(0xFF0F766E) : Colors.black87),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                if (sublabel != null)
                  Text(sublabel!,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text(value, style: valueStyle),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onTap,
              child: Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey.shade400),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Error View ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('পুনরায় চেষ্টা করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
