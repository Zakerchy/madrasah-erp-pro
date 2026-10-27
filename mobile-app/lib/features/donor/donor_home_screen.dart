import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../shared/constants/fund_types.dart';
import 'donor_api.dart';
import 'donor_session.dart';
import 'donor_login_screen.dart';
import 'donor_donate_screen.dart';
import 'donor_dashboard_screen.dart';
import 'widgets/islamic_slider.dart';

class DonorHomeScreen extends StatefulWidget {
  const DonorHomeScreen({super.key});

  @override
  State<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> {
  List<Map<String, dynamic>> _opportunities = [];
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _loadNotifications();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await DonorApi.listOpportunities();
      if (res['ok'] == true) {
        final raw = res['data'] as List? ?? [];
        setState(() => _opportunities = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      } else {
        setState(() => _error = res['message'] as String?);
      }
    } catch (e) {
      setState(() => _error = AppLang.t('সংযোগ ত্রুটি', 'Connection error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final res = await DonorApi.myNotifications(DonorSession.donorId!, DonorSession.donorToken!);
      if (res['ok'] == true && mounted) {
        final raw = res['data'] as List? ?? [];
        setState(() => _notifications = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    await DonorSession.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DonorLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLang.t('দানকারী হোম', 'Donor Home')),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: AppLang.t('আমার ড্যাশবোর্ড', 'My Dashboard'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DonorDashboardScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppLang.t('লগআউট', 'Logout'),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _load();
          await _loadNotifications();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome
                    Card(
                      color: cs.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: cs.primary,
                              child: Text(
                                DonorSession.nameBn.isNotEmpty ? DonorSession.nameBn[0] : '?',
                                style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLang.t('আস-সালামু আলাইকুম,', 'As-Salamu Alaykum,'),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    DonorSession.nameBn,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_notifications.isNotEmpty) ...[
                      ..._notifications.map((n) => Card(
                            color: cs.tertiaryContainer,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.campaign_outlined, color: cs.onTertiaryContainer, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if ((n['title_bn'] as String?)?.isNotEmpty ?? false)
                                          Text(n['title_bn'] as String,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text(n['message_bn'] as String? ?? '', style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                      const SizedBox(height: 8),
                    ],
                    const IslamicSlider(height: 150),
                    const SizedBox(height: 16),
                    Text(
                      AppLang.t('দানের সুযোগ', 'Donation Opportunities'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            if (_loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: TextStyle(color: cs.error)),
                      TextButton(onPressed: _load, child: Text(AppLang.t('আবার চেষ্টা', 'Retry'))),
                    ],
                  ),
                ),
              )
            else if (_opportunities.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _KhatTable(opportunities: _buildDefaultOpportunities()),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _KhatTable(opportunities: _opportunities),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DonorDonateScreen()),
        ).then((_) => _load()),
        icon: const Icon(Icons.volunteer_activism),
        label: Text(AppLang.t('দান করুন', 'Donate')),
      ),
    );
  }

  List<Map<String, dynamic>> _buildDefaultOpportunities() {
    return FundTypes.all.where((f) => f.donorVisible).map((f) => {
      'fund_type': f.key,
      'title_bn': f.labelBn,
      'title_en': f.labelEn,
      'description_bn': f.descBn,
      'target_amount': 0,
      'collected_amount': 0,
    }).toList();
  }
}

class _KhatTable extends StatelessWidget {
  final List<Map<String, dynamic>> opportunities;
  const _KhatTable({required this.opportunities});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: opportunities.map((opp) {
        final target = (opp['target_amount'] as num?)?.toDouble() ?? 0;
        final collected = (opp['collected_amount'] as num?)?.toDouble() ?? 0;
        final progress = target > 0 ? (collected / target).clamp(0.0, 1.0) : null;
        final ft = FundTypes.byKey(opp['fund_type'] as String?);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_fundIcon(opp['fund_type'] as String? ?? ''), color: cs.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLang.isEnglish.value
                            ? (opp['title_en'] as String? ?? ft?.labelEn ?? '')
                            : (opp['title_bn'] as String? ?? ft?.labelBn ?? ''),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                if ((opp['description_bn'] as String?)?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text(
                    opp['description_bn'] as String,
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress, minHeight: 6, borderRadius: BorderRadius.circular(3)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('৳ ${_fmt(collected)} ${AppLang.t("সংগৃহীত", "collected")}',
                        style: const TextStyle(fontSize: 11)),
                      Text('লক্ষ্য ৳ ${_fmt(target)}', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  IconData _fundIcon(String key) {
    switch (key) {
      case 'ZAKAT': return Icons.account_balance;
      case 'TALEBE_ELM': return Icons.menu_book;
      case 'YATIM': return Icons.child_care;
      case 'BIA': return Icons.celebration;
      case 'EID': return Icons.star;
      case 'IFTAR': return Icons.restaurant;
      case 'FITRA': return Icons.volunteer_activism;
      case 'LIBRARY': return Icons.library_books;
      case 'WATER': return Icons.water_drop;
      default: return Icons.favorite;
    }
  }
}
