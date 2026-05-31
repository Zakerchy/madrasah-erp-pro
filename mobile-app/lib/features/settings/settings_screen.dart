import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../shared/models/notification_settings.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _api = ApiService();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String _role = 'VIEWER';
  String _approvalStatus = 'APPROVED';
  bool _active = true;

  bool _saving = false;
  bool _loadingUsers = true;
  bool _loadingNotify = true;
  bool _savingNotify = false;
  bool _loadingNotifyEvents = false;
  String _health = 'Not checked';
  NotificationSettings _notify = NotificationSettings.defaults();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _notifyEvents = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadNotificationSettings();
    _loadNotificationEvents();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    final res = await _api.get('listUsers');
    if (!mounted) return;

    if (res['ok'] == true) {
      final data = (res['data'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      data.sort((a, b) =>
          (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
      setState(() {
        _users = data;
        _loadingUsers = false;
      });
    } else {
      setState(() => _loadingUsers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${res['message'] ?? res['error'] ?? AppLang.t('ব্যবহারকারী লোড ব্যর্থ', 'Failed to load users')}')),
      );
    }
  }

  Future<void> _loadNotificationSettings() async {
    setState(() => _loadingNotify = true);
    final res = await _api.get('getNotificationSettings');
    if (!mounted) return;
    if (res['ok'] == true) {
      final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
      setState(() {
        _notify = NotificationSettings.fromApi(data);
        _loadingNotify = false;
      });
      return;
    }

    setState(() => _loadingNotify = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${res['message'] ?? res['error'] ?? AppLang.t('নোটিফিকেশন সেটিংস লোড ব্যর্থ', 'Failed to load notification settings')}',
        ),
      ),
    );
  }

  Future<void> _saveNotificationSettings() async {
    setState(() => _savingNotify = true);
    final res = await _api.post(
        'upsertNotificationSettings',
        {
          'user_role': SessionService.role,
          'payload': _notify.toPayload(),
        },
        allowQueue: false);

    if (!mounted) return;
    setState(() => _savingNotify = false);

    if (res['ok'] == true) {
      final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
      setState(() => _notify = NotificationSettings.fromApi(data));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLang.t('নোটিফিকেশন সেটিংস সেভ হয়েছে',
                'Notification settings saved'))),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${res['message'] ?? res['error'] ?? AppLang.t('সেভ ব্যর্থ', 'Save failed')}',
        ),
      ),
    );
  }

  Future<void> _loadNotificationEvents() async {
    setState(() => _loadingNotifyEvents = true);
    final res = await _api.get('listInAppNotifications');
    if (!mounted) return;
    if (res['ok'] == true) {
      final items = (res['data'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _notifyEvents = items;
        _loadingNotifyEvents = false;
      });
      return;
    }
    setState(() => _loadingNotifyEvents = false);
  }

  Future<void> _createUser() async {
    final name = _name.text.trim();
    final email = _email.text.trim().toLowerCase();
    final phone = _phone.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLang.t(
              'নাম ও ইমেইল প্রয়োজন', 'Name and email are required'))));
      return;
    }

    setState(() => _saving = true);
    final payload = {
      'id': 'u_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'email': email,
      'phone': phone,
      'role': _role,
      'active': _active ? 'TRUE' : 'FALSE',
      'approval_status': _approvalStatus,
      'pin_hash': '',
    };

    final res = await _api.post('upsertUser', {
      'user_role': SessionService.role,
      'payload': payload,
    });

    if (!mounted) return;
    setState(() => _saving = false);

    if (res['ok'] == true) {
      _name.clear();
      _email.clear();
      _phone.clear();
      _role = 'VIEWER';
      _approvalStatus = 'APPROVED';
      _active = true;
      await _loadUsers();

      final msg = res['queued'] == true
          ? AppLang.t(
              'অফলাইনে সংরক্ষিত।', 'Offline saved. Will sync automatically.')
          : AppLang.t('ব্যবহারকারী তৈরি সফল', 'User created successfully');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${res['message'] ?? res['error'] ?? AppLang.t('ব্যবহারকারী তৈরি ব্যর্থ', 'User create failed')}')),
      );
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    setState(() => _saving = true);

    final payload = {
      'id': (user['id'] ?? '').toString(),
      'name': (user['name'] ?? '').toString(),
      'email': (user['email'] ?? '').toString(),
      'phone': (user['phone'] ?? '').toString(),
      'role': (user['role'] ?? 'VIEWER').toString(),
      'active': (user['active'] ?? 'TRUE').toString().toUpperCase() == 'TRUE'
          ? 'FALSE'
          : 'TRUE',
      'approval_status': (user['approval_status'] ?? 'APPROVED').toString(),
      'pin_hash': (user['pin_hash'] ?? '').toString(),
    };

    final res = await _api.post('upsertUser', {
      'user_role': SessionService.role,
      'payload': payload,
    });

    if (!mounted) return;
    setState(() => _saving = false);

    if (res['ok'] == true) {
      await _loadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('${res['message'] ?? res['error'] ?? 'Update failed'}')),
      );
    }
  }

  Future<void> _setApprovalStatus(
      Map<String, dynamic> user, String status) async {
    setState(() => _saving = true);
    final res = await _api.post('setUserApprovalStatus', {
      'user_role': SessionService.role,
      'payload': {
        'id': (user['id'] ?? '').toString(),
        'approval_status': status,
      },
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (res['ok'] == true) {
      await _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('${AppLang.t('অবস্থা আপডেট', 'Status updated')}: $status')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${res['message'] ?? res['error'] ?? AppLang.t('আপডেট ব্যর্থ', 'Status update failed')}')),
      );
    }
  }

  Future<void> _generateTempToken(Map<String, dynamic> user) async {
    setState(() => _saving = true);
    final res = await _api.post('generateTempResetToken', {
      'user_role': SessionService.role,
      'payload': {
        'id': (user['id'] ?? '').toString(),
        'expires_in_minutes': 30,
      },
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (res['ok'] == true) {
      final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
      final token = (data['token'] ?? '').toString();
      final expires = (data['expires_at'] ?? '').toString();
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLang.t('রিসেট টোকেন', 'Temporary Reset Token')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${AppLang.t('ব্যবহারকারী', 'User')}: ${(user['name'] ?? '').toString()}'),
                const SizedBox(height: 8),
                SelectableText('${AppLang.t('টোকেন', 'Token')}: $token',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${AppLang.t('মেয়াদ', 'Expires')}: $expires'),
                const SizedBox(height: 8),
                Text(
                    AppLang.t('এই টোকেনটি নিরাপদে শেয়ার করুন।',
                        'Share this token securely. It can be used once before expiry.'),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            actions: [
              FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK')),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${res['message'] ?? res['error'] ?? 'Token generate failed'}')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
        return Colors.red;
      case 'BLOCKED':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  String _statusOf(Map<String, dynamic> u) {
    final raw = (u['approval_status'] ?? '').toString().trim().toUpperCase();
    if (raw.isNotEmpty) return raw;
    return (u['active'] ?? '').toString().toUpperCase() == 'TRUE'
        ? 'APPROVED'
        : 'PENDING';
  }

  Future<void> _checkHealth() async {
    final res = await _api.get('health');
    if (!mounted) return;
    setState(() {
      _health = res['ok'] == true
          ? '${AppLang.t('সংযুক্ত', 'OK')} - ${res['ts'] ?? ''}'
          : AppLang.t('সংযোগ ব্যর্থ', 'Failed');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLang.isEnglish,
      builder: (context, isEn, _) => BaseScaffold(
        title: AppLang.t('সেটিংস', 'Settings'),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Language toggle
            Card(
              child: SwitchListTile(
                value: isEn,
                onChanged: (v) => AppLang.setEnglish(v),
                title: const Text('English / বাংলা'),
                subtitle:
                    Text(isEn ? 'English mode is on' : 'বাংলা মোড চালু আছে'),
                secondary: const Icon(Icons.language),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLang.t('নোটিফিকেশন কন্ট্রোল', 'Notification Controls'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLang.t(
                        'In-app notification সবসময় চালু থাকবে। Email category-wise ON/OFF করতে পারবেন।',
                        'In-app notifications are always enabled. Email can be toggled per category.',
                      ),
                      style:
                          TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    if (_loadingNotify)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      SwitchListTile(
                        value: _notify.inAppEnabled,
                        onChanged: null,
                        title: Text(AppLang.t(
                            'In-app notification', 'In-app notification')),
                        subtitle: Text(AppLang.t('ডিফল্টভাবে সবসময় চালু',
                            'Always enabled by default')),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        value: _notify.emailApproval,
                        onChanged: _savingNotify
                            ? null
                            : (v) => setState(() =>
                                _notify = _notify.copyWith(emailApproval: v)),
                        title: Text(AppLang.t(
                            'Approval status email', 'Approval status email')),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        value: _notify.emailFailedSync,
                        onChanged: _savingNotify
                            ? null
                            : (v) => setState(() =>
                                _notify = _notify.copyWith(emailFailedSync: v)),
                        title: Text(AppLang.t(
                            'Failed sync email', 'Failed sync email')),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        value: _notify.emailDailySummary,
                        onChanged: _savingNotify
                            ? null
                            : (v) => setState(() => _notify =
                                _notify.copyWith(emailDailySummary: v)),
                        title: Text(AppLang.t(
                            'Daily summary email', 'Daily summary email')),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        value: _notify.emailDueReminder,
                        onChanged: _savingNotify
                            ? null
                            : (v) => setState(() => _notify =
                                _notify.copyWith(emailDueReminder: v)),
                        title: Text(AppLang.t(
                            'Due reminder email', 'Due reminder email')),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        value: _notify.emailSecurityAlert,
                        onChanged: _savingNotify
                            ? null
                            : (v) => setState(() => _notify =
                                _notify.copyWith(emailSecurityAlert: v)),
                        title: Text(AppLang.t(
                            'Security alert email', 'Security alert email')),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: _savingNotify
                                ? null
                                : _saveNotificationSettings,
                            icon: _savingNotify
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(AppLang.t('সেভ করুন', 'Save')),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _savingNotify
                                ? null
                                : _loadNotificationSettings,
                            icon: const Icon(Icons.refresh),
                            label: Text(AppLang.t('রিফ্রেশ', 'Refresh')),
                          ),
                        ],
                      ),
                      if (_notify.updatedAt.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${AppLang.t('সর্বশেষ আপডেট', 'Last updated')}: ${_notify.updatedAt}',
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            AppLang.t('In-app notification feed',
                                'In-app notification feed'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _loadingNotifyEvents
                                ? null
                                : _loadNotificationEvents,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                      if (_loadingNotifyEvents)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_notifyEvents.isEmpty)
                        Text(
                          AppLang.t('এখনো কোনো notification event নেই',
                              'No notification events yet'),
                          style: TextStyle(color: Colors.grey.shade700),
                        )
                      else
                        ..._notifyEvents.take(6).map(
                              (e) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  (e['title'] ?? '').toString(),
                                  style: const TextStyle(fontSize: 13),
                                ),
                                subtitle: Text(
                                  '${(e['category'] ?? '').toString()} • ${(e['created_at'] ?? '').toString()}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 28),
            Text(AppLang.t('ব্যবহারকারী ব্যবস্থাপনা', 'Admin User Management'),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
                controller: _name,
                decoration:
                    InputDecoration(labelText: AppLang.t('নাম', 'Name'))),
            const SizedBox(height: 8),
            TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    labelText: AppLang.t('ইমেইল (Gmail)', 'Email (Gmail)'))),
            const SizedBox(height: 8),
            TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                    labelText: AppLang.t('ফোন (ঐচ্ছিক)', 'Phone (optional)'))),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _role,
              items: const [
                DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                DropdownMenuItem(
                    value: 'ACCOUNTANT', child: Text('ACCOUNTANT')),
                DropdownMenuItem(
                    value: 'FIELD_USER', child: Text('FIELD_USER')),
                DropdownMenuItem(value: 'VIEWER', child: Text('VIEWER')),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'VIEWER'),
              decoration:
                  InputDecoration(labelText: AppLang.t('ভূমিকা', 'Role')),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _approvalStatus,
              items: const [
                DropdownMenuItem(value: 'APPROVED', child: Text('APPROVED')),
                DropdownMenuItem(value: 'PENDING', child: Text('PENDING')),
                DropdownMenuItem(value: 'REJECTED', child: Text('REJECTED')),
                DropdownMenuItem(value: 'BLOCKED', child: Text('BLOCKED')),
              ],
              onChanged: (v) =>
                  setState(() => _approvalStatus = v ?? 'APPROVED'),
              decoration: InputDecoration(
                  labelText: AppLang.t('অনুমোদন অবস্থা', 'Approval Status')),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: Text(AppLang.t('সক্রিয় ব্যবহারকারী', 'Active user')),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saving ? null : _createUser,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.person_add),
              label: Text(_saving
                  ? AppLang.t('সংরক্ষণ হচ্ছে...', 'Saving...')
                  : AppLang.t('ব্যবহারকারী তৈরি করুন', 'Create User')),
            ),
            const Divider(height: 28),
            Row(
              children: [
                Text(AppLang.t('ব্যবহারকারীর তালিকা', 'User List'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    onPressed: _loadUsers, icon: const Icon(Icons.refresh)),
              ],
            ),
            if (_loadingUsers)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_users.isEmpty)
              Text(AppLang.t('কোনো ব্যবহারকারী নেই', 'No users found'))
            else
              ..._users.map(
                (u) => Card(
                  child: ListTile(
                    title: Text('${u['name'] ?? ''} (${u['role'] ?? ''})'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${u['email'] ?? ''} • ${u['phone'] ?? ''}'),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Chip(
                              label: Text(_statusOf(u)),
                              backgroundColor:
                                  _statusColor(_statusOf(u)).withOpacity(0.15),
                              side:
                                  BorderSide(color: _statusColor(_statusOf(u))),
                            ),
                            Chip(
                              label: Text((u['active'] ?? 'FALSE')
                                          .toString()
                                          .toUpperCase() ==
                                      'TRUE'
                                  ? AppLang.t('সক্রিয়', 'ACTIVE')
                                  : AppLang.t('নিষ্ক্রিয়', 'INACTIVE')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: _saving
                                  ? null
                                  : () => _setApprovalStatus(u, 'APPROVED'),
                              child: Text(AppLang.t('অনুমোদন', 'Approve')),
                            ),
                            OutlinedButton(
                              onPressed: _saving
                                  ? null
                                  : () => _setApprovalStatus(u, 'PENDING'),
                              child: Text(AppLang.t('অপেক্ষমান', 'Pending')),
                            ),
                            OutlinedButton(
                              onPressed: _saving
                                  ? null
                                  : () => _setApprovalStatus(u, 'REJECTED'),
                              child: Text(AppLang.t('প্রত্যাখ্যান', 'Reject')),
                            ),
                            OutlinedButton(
                              onPressed: _saving
                                  ? null
                                  : () => _setApprovalStatus(u, 'BLOCKED'),
                              child: Text(AppLang.t('ব্লক', 'Block')),
                            ),
                            FilledButton.tonal(
                              onPressed:
                                  _saving ? null : () => _generateTempToken(u),
                              child:
                                  Text(AppLang.t('রিসেট টোকেন', 'Reset Token')),
                            ),
                            TextButton(
                              onPressed:
                                  _saving ? null : () => _toggleActive(u),
                              child: Text(
                                (u['active'] ?? 'FALSE')
                                            .toString()
                                            .toUpperCase() ==
                                        'TRUE'
                                    ? AppLang.t('নিষ্ক্রিয় করুন', 'Deactivate')
                                    : AppLang.t('সক্রিয় করুন', 'Activate'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                ),
              ),
            const Divider(height: 28),
            Text(AppLang.t('সিস্টেম পরীক্ষা', 'System Check'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FilledButton.icon(
                onPressed: _checkHealth,
                icon: const Icon(Icons.health_and_safety),
                label: Text(AppLang.t(
                    'ডেটা সংযোগ পরীক্ষা করুন', 'Check Data Connection'))),
            const SizedBox(height: 8),
            Text('${AppLang.t('স্বাস্থ্য', 'Health')}: $_health'),
          ],
        ),
      ),
    );
  }
}
