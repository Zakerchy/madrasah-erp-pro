import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../shared/constants/fund_types.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';

class DonorBroadcastScreen extends StatefulWidget {
  const DonorBroadcastScreen({super.key});

  @override
  State<DonorBroadcastScreen> createState() => _DonorBroadcastScreenState();
}

class _DonorBroadcastScreenState extends State<DonorBroadcastScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _api = ApiService();

  List<Map<String, dynamic>> _sent = [];
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _donors = [];
  bool _loadingSent = true;
  bool _loadingSchedules = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadSent();
    _loadSchedules();
    _loadDonors();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadSent({bool forceRefresh = false}) async {
    setState(() => _loadingSent = true);
    final res = await _api.get('adminListDonorNotifications', forceRefresh: forceRefresh);
    if (mounted && res['ok'] == true) {
      final raw = res['data'] as List? ?? [];
      setState(() => _sent = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    }
    if (mounted) setState(() => _loadingSent = false);
  }

  Future<void> _loadSchedules({bool forceRefresh = false}) async {
    setState(() => _loadingSchedules = true);
    final res = await _api.get('adminListDonorReminderSchedules', forceRefresh: forceRefresh);
    if (mounted && res['ok'] == true) {
      final raw = res['data'] as List? ?? [];
      setState(() => _schedules = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    }
    if (mounted) setState(() => _loadingSchedules = false);
  }

  Future<void> _loadDonors() async {
    final res = await _api.get('adminListAllDonors');
    if (mounted && res['ok'] == true) {
      final raw = res['data'] as List? ?? [];
      setState(() => _donors = raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((d) => d['status'] == 'ACTIVE')
          .toList());
    }
  }

  Future<void> _deleteOne(String id) async {
    final res = await _api.post('adminDeleteDonorNotification', {
      'user_role': SessionService.role,
      'payload': {'id': id},
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['ok'] == true ? AppLang.t('মুছে ফেলা হয়েছে', 'Deleted')
            : (res['message'] as String? ?? AppLang.t('ত্রুটি', 'Error'))),
      ));
      _loadSent(forceRefresh: true);
    }
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLang.t('সব মুছে ফেলবেন?', 'Delete all?')),
        content: Text(AppLang.t('সব পাঠানো বিজ্ঞপ্তি স্থায়ীভাবে মুছে যাবে।', 'All sent notifications will be permanently deleted.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLang.t('বাতিল', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLang.t('মুছুন', 'Delete'))),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await _api.post('adminDeleteDonorNotification', {
      'user_role': SessionService.role,
      'payload': {'all': true},
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['ok'] == true ? AppLang.t('সব মুছে ফেলা হয়েছে', 'All deleted')
            : (res['message'] as String? ?? AppLang.t('ত্রুটি', 'Error'))),
      ));
      _loadSent(forceRefresh: true);
    }
  }

  Future<void> _deleteSchedule(String id) async {
    final res = await _api.post('deleteDonorReminderSchedule', {
      'user_role': SessionService.role,
      'payload': {'id': id},
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['ok'] == true ? AppLang.t('মুছে ফেলা হয়েছে', 'Deleted')
            : (res['message'] as String? ?? AppLang.t('ত্রুটি', 'Error'))),
      ));
      _loadSchedules(forceRefresh: true);
    }
  }

  Future<void> _toggleSchedule(Map<String, dynamic> s, bool enabled) async {
    await _api.post('setDonorReminderSchedule', {
      'user_role': SessionService.role,
      'payload': {
        'donor_id': s['donor_id'],
        'donor_name_bn': s['donor_name_bn'],
        'fund_type': s['fund_type'],
        'interval_days': s['interval_days'],
        'message_bn': s['message_bn'],
        'enabled': enabled,
      },
    });
    _loadSchedules(forceRefresh: true);
  }

  Future<void> _openComposeDialog() async {
    bool recurring = false;
    String target = 'ALL';
    final selectedMultiIds = <String>{};
    String? selectedDonorId;
    String fundType = FundTypes.all.first.key;
    final messageCtrl = TextEditingController();
    final intervalCtrl = TextEditingController(text: '30');

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(AppLang.t('নতুন বার্তা', 'New Message')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppLang.t('নিয়মিত রিমাইন্ডার (একজন দানকারীর জন্য)', 'Recurring reminder (single donor)')),
                  value: recurring,
                  onChanged: (v) => setDlg(() => recurring = v),
                ),
                const SizedBox(height: 8),
                if (!recurring) ...[
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: 'ALL', groupValue: target,
                    title: Text(AppLang.t('সব দানকারী', 'All donors')),
                    onChanged: (v) => setDlg(() => target = v!),
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: 'MULTI', groupValue: target,
                    title: Text(AppLang.t('তালিকা থেকে বেছে নিন', 'Select from list')),
                    onChanged: (v) => setDlg(() => target = v!),
                  ),
                  if (target == 'MULTI')
                    SizedBox(
                      height: 180,
                      child: ListView(
                        children: _donors.map((d) => CheckboxListTile(
                              dense: true,
                              value: selectedMultiIds.contains(d['id']),
                              title: Text('${d['name_bn']} (${d['phone']})'),
                              onChanged: (v) => setDlg(() {
                                if (v == true) {
                                  selectedMultiIds.add(d['id'] as String);
                                } else {
                                  selectedMultiIds.remove(d['id']);
                                }
                              }),
                            )).toList(),
                      ),
                    ),
                ] else ...[
                  DropdownButtonFormField<String>(
                    initialValue: selectedDonorId,
                    decoration: InputDecoration(labelText: AppLang.t('দানকারী', 'Donor')),
                    items: _donors.map((d) => DropdownMenuItem(
                        value: d['id'] as String, child: Text('${d['name_bn']} (${d['phone']})'))).toList(),
                    onChanged: (v) => setDlg(() => selectedDonorId = v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: intervalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: AppLang.t('কত দিন পর পর', 'Every N days')),
                  ),
                ],
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: fundType,
                  decoration: InputDecoration(labelText: AppLang.t('খাত (ঐচ্ছিক)', 'Fund (optional)')),
                  items: FundTypes.all.map((f) => DropdownMenuItem(
                      value: f.key, child: Text(AppLang.isEnglish.value ? f.labelEn : f.labelBn))).toList(),
                  onChanged: (v) => setDlg(() => fundType = v ?? fundType),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: messageCtrl,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(labelText: AppLang.t('মেসেজ', 'Message')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLang.t('বাতিল', 'Cancel'))),
            FilledButton(
              onPressed: () async {
                if (messageCtrl.text.trim().isEmpty) return;
                Map<String, dynamic> res;
                if (recurring) {
                  if (selectedDonorId == null) return;
                  final d = _donors.firstWhere((e) => e['id'] == selectedDonorId);
                  res = await _api.post('setDonorReminderSchedule', {
                    'user_role': SessionService.role,
                    'payload': {
                      'donor_id': selectedDonorId,
                      'donor_name_bn': d['name_bn'],
                      'fund_type': fundType,
                      'interval_days': int.tryParse(intervalCtrl.text.trim()) ?? 30,
                      'message_bn': messageCtrl.text.trim(),
                      'enabled': true,
                    },
                  });
                } else {
                  final payload = <String, dynamic>{
                    'target': target,
                    'fund_type': fundType,
                    'message_bn': messageCtrl.text.trim(),
                  };
                  if (target == 'MULTI') {
                    if (selectedMultiIds.isEmpty) return;
                    payload['donor_ids'] = selectedMultiIds.toList();
                  }
                  res = await _api.post('sendDonorNotification', {
                    'user_role': SessionService.role,
                    'payload': payload,
                  });
                }
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(res['ok'] == true ? AppLang.t('সম্পন্ন', 'Done')
                        : (res['message'] as String? ?? AppLang.t('ত্রুটি', 'Error'))),
                  ));
                  _loadSent(forceRefresh: true);
                  _loadSchedules(forceRefresh: true);
                }
              },
              child: Text(AppLang.t('সংরক্ষণ', 'Save')),
            ),
          ],
        ),
      ),
    );
  }

  String _date(dynamic v) {
    final s = (v as String?) ?? '';
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLang.t('বিজ্ঞপ্তি ও রিমাইন্ডার', 'Notifications & Reminders')),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: AppLang.t('পাঠানো বার্তা', 'Sent')),
            Tab(text: AppLang.t('রিমাইন্ডার শিডিউল', 'Schedules')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openComposeDialog,
        icon: const Icon(Icons.add),
        label: Text(AppLang.t('নতুন বার্তা', 'New Message')),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // Sent
          _loadingSent
              ? const Center(child: CircularProgressIndicator())
              : _sent.isEmpty
                  ? Center(child: Text(AppLang.t('কোনো বিজ্ঞপ্তি পাঠানো হয়নি', 'No notifications sent')))
                  : RefreshIndicator(
                      onRefresh: () async => _loadSent(forceRefresh: true),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _deleteAll,
                              icon: const Icon(Icons.delete_sweep, size: 18),
                              label: Text(AppLang.t('সব মুছুন', 'Delete all')),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: _sent.length,
                              itemBuilder: (_, i) {
                                final n = _sent[i];
                                final targetLabel = (n['donor_id'] as String?)?.isEmpty ?? true
                                    ? AppLang.t('সব দানকারী', 'All donors')
                                    : (n['donor_id'] as String);
                                return Card(
                                  child: ListTile(
                                    title: Text(n['message_bn'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                                    subtitle: Text('$targetLabel • ${_date(n['created_at'])}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _deleteOne(n['id'] as String),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
          // Schedules
          _loadingSchedules
              ? const Center(child: CircularProgressIndicator())
              : _schedules.isEmpty
                  ? Center(child: Text(AppLang.t('কোনো রিমাইন্ডার শিডিউল নেই', 'No reminder schedules')))
                  : RefreshIndicator(
                      onRefresh: () async => _loadSchedules(forceRefresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _schedules.length,
                        itemBuilder: (_, i) {
                          final s = _schedules[i];
                          final enabled = s['enabled'] == true || s['enabled'] == 'TRUE' || s['enabled'] == '1';
                          return Card(
                            child: ListTile(
                              title: Text('${s['donor_name_bn']} — প্রতি ${s['interval_days']} দিনে'),
                              subtitle: Text(s['message_bn'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(value: enabled, onChanged: (v) => _toggleSchedule(s, v)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _deleteSchedule(s['id'] as String),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}
