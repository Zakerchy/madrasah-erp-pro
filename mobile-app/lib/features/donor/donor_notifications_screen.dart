import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import 'donor_api.dart';
import 'donor_session.dart';

class DonorNotificationsScreen extends StatefulWidget {
  const DonorNotificationsScreen({super.key});

  @override
  State<DonorNotificationsScreen> createState() => _DonorNotificationsScreenState();
}

class _DonorNotificationsScreenState extends State<DonorNotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await DonorApi.myNotifications(DonorSession.donorId!, DonorSession.donorToken!);
      if (res['ok'] == true && mounted) {
        final raw = res['data'] as List? ?? [];
        setState(() => _notifications = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _formatDate(dynamic v) {
    final s = (v as String?) ?? '';
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(AppLang.t('বিজ্ঞপ্তি', 'Notifications'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _notifications.isEmpty
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(child: Text(AppLang.t('কোনো বিজ্ঞপ্তি নেই', 'No notifications'))),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final n = _notifications[i];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.campaign_outlined, color: cs.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if ((n['title_bn'] as String?)?.isNotEmpty ?? false)
                                        Text(n['title_bn'] as String,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text(n['message_bn'] as String? ?? '', style: const TextStyle(fontSize: 13)),
                                      const SizedBox(height: 6),
                                      Text(_formatDate(n['created_at']),
                                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
