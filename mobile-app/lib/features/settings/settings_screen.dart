import 'package:flutter/material.dart';

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
  String _health = 'Not checked';

  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
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
      data.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
      setState(() {
        _users = data;
        _loadingUsers = false;
      });
    } else {
      setState(() => _loadingUsers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${res['message'] ?? res['error'] ?? 'Failed to load users'}')),
      );
    }
  }

  Future<void> _createUser() async {
    final name = _name.text.trim();
    final email = _email.text.trim().toLowerCase();
    final phone = _phone.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and email are required')));
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
          ? 'Offline saved. User will sync automatically later.'
          : 'User created successfully';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${res['message'] ?? res['error'] ?? 'User create failed'}')),
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
      'active': (user['active'] ?? 'TRUE').toString().toUpperCase() == 'TRUE' ? 'FALSE' : 'TRUE',
      'approval_status': (user['approval_status'] ?? 'APPROVED').toString(),
      'pin_hash': '',
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
        SnackBar(content: Text('${res['message'] ?? res['error'] ?? 'Update failed'}')),
      );
    }
  }

  Future<void> _setApprovalStatus(Map<String, dynamic> user, String status) async {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${res['message'] ?? res['error'] ?? 'Status update failed'}')),
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
            title: const Text('Temporary Reset Token'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User: ${(user['name'] ?? '').toString()}'),
                const SizedBox(height: 8),
                SelectableText('Token: $token', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Expires: $expires'),
                const SizedBox(height: 8),
                const Text('Share this token securely. It can be used once before expiry.', style: TextStyle(fontSize: 12)),
              ],
            ),
            actions: [
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${res['message'] ?? res['error'] ?? 'Token generate failed'}')),
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
    return (u['active'] ?? '').toString().toUpperCase() == 'TRUE' ? 'APPROVED' : 'PENDING';
  }

  Future<void> _checkHealth() async {
    final res = await _api.get('health');
    if (!mounted) return;
    setState(() {
      _health = res['ok'] == true ? 'OK - ${res['ts'] ?? ''}' : 'Failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Admin User Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 8),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email (Gmail)')),
          const SizedBox(height: 8),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (optional)')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _role,
            items: const [
              DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
              DropdownMenuItem(value: 'ACCOUNTANT', child: Text('ACCOUNTANT')),
              DropdownMenuItem(value: 'FIELD_USER', child: Text('FIELD_USER')),
              DropdownMenuItem(value: 'VIEWER', child: Text('VIEWER')),
            ],
            onChanged: (v) => setState(() => _role = v ?? 'VIEWER'),
            decoration: const InputDecoration(labelText: 'Role'),
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
            onChanged: (v) => setState(() => _approvalStatus = v ?? 'APPROVED'),
            decoration: const InputDecoration(labelText: 'Approval Status'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _active,
            onChanged: (v) => setState(() => _active = v),
            title: const Text('Active user'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _saving ? null : _createUser,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.person_add),
            label: Text(_saving ? 'Saving...' : 'Create User'),
          ),
          const Divider(height: 28),
          Row(
            children: [
              const Text('User List', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: _loadUsers, icon: const Icon(Icons.refresh)),
            ],
          ),
          if (_loadingUsers)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_users.isEmpty)
            const Text('No users found')
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
                            backgroundColor: _statusColor(_statusOf(u)).withOpacity(0.15),
                            side: BorderSide(color: _statusColor(_statusOf(u))),
                          ),
                          Chip(
                            label: Text((u['active'] ?? 'FALSE').toString().toUpperCase() == 'TRUE' ? 'ACTIVE' : 'INACTIVE'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: _saving ? null : () => _setApprovalStatus(u, 'APPROVED'),
                            child: const Text('Approve'),
                          ),
                          OutlinedButton(
                            onPressed: _saving ? null : () => _setApprovalStatus(u, 'PENDING'),
                            child: const Text('Pending'),
                          ),
                          OutlinedButton(
                            onPressed: _saving ? null : () => _setApprovalStatus(u, 'REJECTED'),
                            child: const Text('Reject'),
                          ),
                          OutlinedButton(
                            onPressed: _saving ? null : () => _setApprovalStatus(u, 'BLOCKED'),
                            child: const Text('Block'),
                          ),
                          FilledButton.tonal(
                            onPressed: _saving ? null : () => _generateTempToken(u),
                            child: const Text('Temp Reset Token'),
                          ),
                          TextButton(
                            onPressed: _saving ? null : () => _toggleActive(u),
                            child: Text(
                              (u['active'] ?? 'FALSE').toString().toUpperCase() == 'TRUE' ? 'Deactivate' : 'Activate',
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
          const Text('System Check', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _checkHealth, icon: const Icon(Icons.health_and_safety), label: const Text('Check Data Connection')),
          const SizedBox(height: 8),
          Text('Health: $_health'),
        ],
      ),
    );
  }
}
