import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../shared/constants/app_permissions.dart';
import '../../shared/models/app_ui_settings.dart';
import '../../shared/models/notification_settings.dart';
import '../../shared/models/role_definition.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/role_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';
import '../../shared/widgets/themed_date_picker.dart';

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
  final _roleKey = TextEditingController();
  final _roleNameBn = TextEditingController();
  final _roleNameEn = TextEditingController();
  final _roleDescription = TextEditingController();
  String _role = 'VIEWER';
  String _approvalStatus = 'APPROVED';
  bool _active = true;
  bool _roleActive = true;
  final Set<String> _rolePermissions = {
    AppPermissions.dashboardView,
    AppPermissions.reportsView,
  };

  bool _saving = false;
  bool _savingRole = false;
  bool _loadingUsers = true;
  bool _loadingRoles = true;
  bool _loadingNotify = true;
  bool _savingNotify = false;
  bool _loadingNotifyEvents = false;
  bool _loadingUiRange = true;
  bool _savingUiRange = false;
  bool _loadingAudit = false;
  bool _checkingLaunch = false;
  String _health = 'Not checked';
  NotificationSettings _notify = NotificationSettings.defaults();
  AppUiSettings _uiSettings = AppUiSettings.defaults();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _notifyEvents = [];
  List<Map<String, dynamic>> _auditRows = [];
  List<Map<String, dynamic>> _launchChecks = [];
  List<RoleDefinition> _roles = [];

  @override
  void initState() {
    super.initState();
    _loadRoles();
    _loadUsers();
    _loadNotificationSettings();
    _loadNotificationEvents();
    _loadAppUiSettings();
    _loadAuditLog();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _roleKey.dispose();
    _roleNameBn.dispose();
    _roleNameEn.dispose();
    _roleDescription.dispose();
    super.dispose();
  }

  Future<void> _loadRoles({bool forceRefresh = false}) async {
    if (!SessionService.can(AppPermissions.rolesView)) {
      setState(() {
        _roles = RoleService.activeDefinitions();
        _loadingRoles = false;
      });
      return;
    }
    setState(() => _loadingRoles = true);
    final res = await _api.get(
      'listRoleDefinitions',
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;
    if (res['ok'] == true) {
      final items = (res['data'] as List<dynamic>? ?? [])
          .map((e) => RoleDefinition.fromMap(Map<String, dynamic>.from(e as Map)))
          .where((e) => e.active)
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      await RoleService.storeDefinitions(items);
      setState(() {
        _roles = items;
        if (!_roles.any((r) => r.key == _role)) {
          _role = _roles.any((r) => r.key == 'VIEWER')
              ? 'VIEWER'
              : (_roles.isEmpty ? 'VIEWER' : _roles.first.key);
        }
        _loadingRoles = false;
      });
      return;
    }

    setState(() {
      _roles = RoleService.activeDefinitions();
      _loadingRoles = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${res['message'] ?? res['error'] ?? AppLang.t('রোল লোড ব্যর্থ', 'Failed to load roles')}',
        ),
      ),
    );
  }

  Future<void> _loadUsers() async {
    if (!SessionService.can(AppPermissions.usersManage)) {
      setState(() {
        _users = [];
        _loadingUsers = false;
      });
      return;
    }
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
    if (!SessionService.can(AppPermissions.notificationsManage)) {
      setState(() => _loadingNotify = false);
      return;
    }
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
    if (!SessionService.can(AppPermissions.notificationsView)) {
      setState(() => _loadingNotifyEvents = false);
      return;
    }
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

  String _fmtDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  int _rangeDaysInclusive(DateTime from, DateTime to) {
    return to.difference(from).inDays + 1;
  }

  Future<void> _loadAppUiSettings() async {
    setState(() => _loadingUiRange = true);
    final res = await _api.get('getAppUiSettings');
    if (!mounted) return;
    if (res['ok'] == true) {
      final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
      setState(() {
        _uiSettings = AppUiSettings.fromApi(data);
        _loadingUiRange = false;
      });
      return;
    }
    setState(() => _loadingUiRange = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${res['message'] ?? res['error'] ?? AppLang.t('ডিফল্ট রেঞ্জ সেটিংস লোড ব্যর্থ', 'Failed to load default range settings')}',
        ),
      ),
    );
  }

  Future<void> _saveAppUiSettings() async {
    final days = _rangeDaysInclusive(
      _uiSettings.defaultFromDate,
      _uiSettings.defaultToDate,
    );
    if (days > _uiSettings.maxRangeDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLang.t(
              'ডিফল্ট রেঞ্জ সর্বোচ্চ ${_uiSettings.maxRangeDays} দিন হতে পারবে',
              'Default range cannot exceed ${_uiSettings.maxRangeDays} days',
            ),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _savingUiRange = true);
    final res = await _api.post(
      'upsertAppUiSettings',
      {
        'user_role': SessionService.role,
        'payload': _uiSettings.toPayload(),
      },
      allowQueue: false,
    );
    if (!mounted) return;
    setState(() => _savingUiRange = false);

    if (res['ok'] == true) {
      final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
      setState(() => _uiSettings = AppUiSettings.fromApi(data));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLang.t('ডিফল্ট রিপোর্ট রেঞ্জ সেভ হয়েছে',
                'Default report range saved'),
          ),
        ),
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

  Future<void> _pickDefaultRangeDate({required bool from}) async {
    final current =
        from ? _uiSettings.defaultFromDate : _uiSettings.defaultToDate;
    final picked = await showThemedDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (from) {
        final nextFrom = DateTime(picked.year, picked.month, picked.day);
        final nextTo = _uiSettings.defaultToDate.isBefore(nextFrom)
            ? nextFrom
            : _uiSettings.defaultToDate;
        _uiSettings = _uiSettings.copyWith(
          defaultFromDate: nextFrom,
          defaultToDate: nextTo,
          defaultToSource: 'FIXED',
        );
      } else {
        final nextTo = DateTime(picked.year, picked.month, picked.day);
        final nextFrom = _uiSettings.defaultFromDate.isAfter(nextTo)
            ? nextTo
            : _uiSettings.defaultFromDate;
        _uiSettings = _uiSettings.copyWith(
          defaultFromDate: nextFrom,
          defaultToDate: nextTo,
          defaultToSource: 'FIXED',
        );
      }
    });
  }

  Future<void> _loadAuditLog() async {
    if (!SessionService.can(AppPermissions.auditView)) {
      return;
    }
    setState(() => _loadingAudit = true);
    final res = await _api.get('listAuditLog', query: {'limit': 20});
    if (!mounted) return;
    if (res['ok'] == true) {
      setState(() {
        _auditRows = (res['data'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loadingAudit = false;
      });
      return;
    }
    setState(() => _loadingAudit = false);
  }

  Future<void> _runLaunchCheck() async {
    setState(() {
      _checkingLaunch = true;
      _launchChecks = [];
    });

    final checks = <Map<String, dynamic>>[];
    Future<void> addCheck(String label, Future<Map<String, dynamic>> call,
        bool Function(Map<String, dynamic>) passWhen) async {
      try {
        final res = await call;
        checks.add({
          'label': label,
          'ok': res['ok'] == true && passWhen(res),
          'note': res['message'] ?? res['error'] ?? '',
        });
      } catch (e) {
        checks.add({'label': label, 'ok': false, 'note': e.toString()});
      }
    }

    await addCheck(
      AppLang.t('API সংযোগ', 'API connection'),
      _api.get('health'),
      (_) => true,
    );
    await addCheck(
      AppLang.t('লেনদেন ডেটা', 'Transaction data'),
      _api.get('datasetStats'),
      (res) {
        final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
        final count =
            int.tryParse((data['txns_active_rows'] ?? '0').toString()) ?? 0;
        return count > 0;
      },
    );
    await addCheck(
      AppLang.t('ডিফল্ট রিপোর্ট রেঞ্জ', 'Default report range'),
      _api.get('getAppUiSettings'),
      (res) {
        final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
        return (data['default_from_date'] ?? '').toString().isNotEmpty &&
            (data['default_to_date'] ?? '').toString().isNotEmpty;
      },
    );
    await addCheck(
      AppLang.t('ব্যবহারকারী', 'Users'),
      _api.get('listUsers'),
      (res) => (res['data'] as List<dynamic>? ?? []).isNotEmpty,
    );

    if (!mounted) return;
    setState(() {
      _launchChecks = checks;
      _checkingLaunch = false;
    });
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
      _role = _roles.any((r) => r.key == 'VIEWER')
          ? 'VIEWER'
          : (_roles.isEmpty ? 'VIEWER' : _roles.first.key);
      _approvalStatus = 'APPROVED';
      _active = true;
      await _loadUsers();
      if (!mounted) return;

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

  Future<void> _createRole() async {
    final key = _roleKey.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z][A-Z0-9_]{1,39}$').hasMatch(key)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLang.t(
              'Role key বড় হাতের অক্ষর/সংখ্যা/underscore হতে হবে',
              'Role key must use uppercase letters, numbers, or underscore',
            ),
          ),
        ),
      );
      return;
    }
    if (_rolePermissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLang.t(
              'কমপক্ষে একটি permission দিন',
              'Select at least one permission',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _savingRole = true);
    final res = await _api.post(
      'upsertRoleDefinition',
      {
        'user_role': SessionService.role,
        'user_id': SessionService.userId,
        'payload': {
          'key': key,
          'name_bn': _roleNameBn.text.trim().isEmpty
              ? key
              : _roleNameBn.text.trim(),
          'name_en': _roleNameEn.text.trim().isEmpty
              ? key
              : _roleNameEn.text.trim(),
          'description': _roleDescription.text.trim(),
          'permissions': _rolePermissions.toList()..sort(),
          'active': _roleActive,
        },
      },
      allowQueue: false,
    );
    if (!mounted) return;
    setState(() => _savingRole = false);

    if (res['ok'] == true) {
      _roleKey.clear();
      _roleNameBn.clear();
      _roleNameEn.clear();
      _roleDescription.clear();
      _rolePermissions
        ..clear()
        ..addAll({
          AppPermissions.dashboardView,
          AppPermissions.reportsView,
        });
      _roleActive = true;
      await _loadRoles(forceRefresh: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLang.t('নতুন রোল সংরক্ষিত হয়েছে', 'Role saved successfully'),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${res['message'] ?? res['error'] ?? AppLang.t('রোল সংরক্ষণ ব্যর্থ', 'Failed to save role')}',
        ),
      ),
    );
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
      if (!mounted) return;
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
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLang.t('ডিফল্ট রিপোর্ট রেঞ্জ', 'Default Report Range'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLang.t(
                        'রিপোর্ট ও ড্যাশবোর্ডে ডিফল্ট date range এখান থেকে নির্ধারণ করুন। বহু বছরের historical data-ও রাখা যাবে।',
                        'Set the default date range for reports and dashboard here. Multi-year historical data is supported.',
                      ),
                      style:
                          TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    if (_loadingUiRange)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _savingUiRange
                                  ? null
                                  : () => _pickDefaultRangeDate(from: true),
                              icon: const Icon(Icons.calendar_month),
                              label: Text(
                                  '${AppLang.t('শুরু', 'From')}: ${_fmtDate(_uiSettings.defaultFromDate)}'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _savingUiRange
                                  ? null
                                  : () => _pickDefaultRangeDate(from: false),
                              icon: const Icon(Icons.event),
                              label: Text(
                                  '${AppLang.t('শেষ', 'To')}: ${_fmtDate(_uiSettings.defaultToDate)}'),
                            ),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        value: _uiSettings.defaultToSource == 'TODAY',
                        onChanged: _savingUiRange
                            ? null
                            : (v) {
                                final now = DateTime.now();
                                final today =
                                    DateTime(now.year, now.month, now.day);
                                setState(() {
                                  _uiSettings = _uiSettings.copyWith(
                                    defaultToSource: v ? 'TODAY' : 'FIXED',
                                    defaultToDate:
                                        v ? today : _uiSettings.defaultToDate,
                                  );
                                });
                              },
                        contentPadding: EdgeInsets.zero,
                        title: Text(AppLang.t('শেষ তারিখ সবসময় আজ ধরা হবে',
                            'Always use today as end date')),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLang.t(
                          'Range length: ${_rangeDaysInclusive(_uiSettings.defaultFromDate, _uiSettings.defaultToDate)} days (max ${_uiSettings.maxRangeDays})',
                          'Range length: ${_rangeDaysInclusive(_uiSettings.defaultFromDate, _uiSettings.defaultToDate)} days (max ${_uiSettings.maxRangeDays})',
                        ),
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed:
                                _savingUiRange ? null : _saveAppUiSettings,
                            icon: _savingUiRange
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
                            onPressed:
                                _savingUiRange ? null : _loadAppUiSettings,
                            icon: const Icon(Icons.refresh),
                            label: Text(AppLang.t('রিফ্রেশ', 'Refresh')),
                          ),
                        ],
                      ),
                      if (_uiSettings.updatedAt.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${AppLang.t('সর্বশেষ আপডেট', 'Last updated')}: ${_uiSettings.updatedAt}',
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 12),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          AppLang.t('গ্লোবাল রোল রেজিস্ট্রি', 'Global Role Registry'),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _loadingRoles
                              ? null
                              : () => _loadRoles(forceRefresh: true),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    Text(
                      AppLang.t(
                        'এখানে role create করলে menu, route guard, write access, এবং backend permission একই definition follow করবে।',
                        'Roles created here drive menu visibility, route guards, write access, and backend permissions globally.',
                      ),
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    if (_loadingRoles)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      TextField(
                        controller: _roleKey,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: AppLang.t('Role Key', 'Role Key'),
                          helperText: 'Example: AUDIT_OFFICER',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _roleNameBn,
                        decoration: InputDecoration(
                          labelText: AppLang.t('বাংলা নাম', 'Bangla Name'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _roleNameEn,
                        decoration: InputDecoration(
                          labelText: AppLang.t('English Name', 'English Name'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _roleDescription,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: AppLang.t('বর্ণনা', 'Description'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _roleActive,
                        onChanged:
                            _savingRole ? null : (v) => setState(() => _roleActive = v),
                        title: Text(AppLang.t('রোল সক্রিয়', 'Role active')),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLang.t('Permissions', 'Permissions'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppPermissions.all.map((permission) {
                          final selected = _rolePermissions.contains(permission);
                          return FilterChip(
                            selected: selected,
                            label: Text(
                              RoleService.permissionLabel(
                                permission,
                                isEnglish: isEn,
                              ),
                            ),
                            onSelected: _savingRole
                                ? null
                                : (value) {
                                    setState(() {
                                      if (value) {
                                        _rolePermissions.add(permission);
                                      } else {
                                        _rolePermissions.remove(permission);
                                      }
                                    });
                                  },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _savingRole ? null : _createRole,
                        icon: _savingRole
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.admin_panel_settings_outlined),
                        label: Text(
                          AppLang.t('রোল সংরক্ষণ', 'Save Role'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        AppLang.t('সক্রিয় রোলসমূহ', 'Active Roles'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ..._roles.map(
                        (role) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('${role.key} • ${isEn ? role.nameEn : role.nameBn}'),
                          subtitle: Text(
                            '${role.permissions.length} ${AppLang.t('টি permission', 'permissions')}'
                            '${role.description.isEmpty ? '' : ' • ${role.description}'}',
                          ),
                          trailing: role.isBuiltin
                              ? Chip(
                                  label: Text(AppLang.t('Built-in', 'Built-in')),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
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
              initialValue: _roles.any((r) => r.key == _role) ? _role : null,
              items: _roles
                  .map(
                    (role) => DropdownMenuItem(
                      value: role.key,
                      child: Text('${role.key} • ${isEn ? role.nameEn : role.nameBn}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _role = v ?? 'VIEWER'),
              decoration:
                  InputDecoration(labelText: AppLang.t('ভূমিকা', 'Role')),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _approvalStatus,
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
                              backgroundColor: _statusColor(_statusOf(u))
                                  .withValues(alpha: 0.15),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLang.t('লঞ্চ রেডিনেস', 'Launch Readiness'),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: _checkingLaunch ? null : _runLaunchCheck,
                          icon: _checkingLaunch
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.fact_check),
                          label:
                              Text(AppLang.t('লঞ্চ চেক', 'Run Launch Check')),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _checkHealth,
                          icon: const Icon(Icons.health_and_safety),
                          label: Text(AppLang.t('API', 'API')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${AppLang.t('স্বাস্থ্য', 'Health')}: $_health',
                        style: TextStyle(color: Colors.grey.shade700)),
                    if (_launchChecks.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ..._launchChecks.map(
                        (c) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            c['ok'] == true
                                ? Icons.check_circle
                                : Icons.error_outline,
                            color: c['ok'] == true
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                          title: Text((c['label'] ?? '').toString()),
                          subtitle: (c['note'] ?? '').toString().isEmpty
                              ? null
                              : Text((c['note'] ?? '').toString()),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (SessionService.can(AppPermissions.auditView))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(AppLang.t('অডিট ট্রেইল', 'Audit Trail'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          IconButton(
                              onPressed: _loadingAudit ? null : _loadAuditLog,
                              icon: const Icon(Icons.refresh)),
                        ],
                      ),
                      if (_loadingAudit)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_auditRows.isEmpty)
                        Text(AppLang.t(
                            'অডিট লগ পাওয়া যায়নি', 'No audit rows found'))
                      else
                        ..._auditRows.take(10).map(
                              (r) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.history),
                                title: Text(
                                    '${r['module'] ?? ''} • ${r['action'] ?? ''}'),
                                subtitle: Text(
                                    '${r['entity_id'] ?? ''} • ${r['done_by'] ?? ''} • ${r['done_at'] ?? ''}'),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
