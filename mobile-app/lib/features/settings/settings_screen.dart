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
                  subtitle: Text('${u['email'] ?? ''} • ${u['phone'] ?? ''}'),
                  trailing: TextButton(
                    onPressed: _saving ? null : () => _toggleActive(u),
                    child: Text(
                      (u['active'] ?? 'FALSE').toString().toUpperCase() == 'TRUE' ? 'Deactivate' : 'Activate',
                    ),
                  ),
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
