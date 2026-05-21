import 'package:flutter/material.dart';

import '../../shared/services/api_service.dart';
import '../../shared/widgets/base_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _api = ApiService();
  final _pin = TextEditingController();

  String _health = 'Not checked';
  String _hash = '';
  bool _loading = false;

  Future<void> _checkHealth() async {
    setState(() => _loading = true);
    final res = await _api.get('health');
    if (!mounted) return;
    setState(() {
      _health = res['ok'] == true ? 'OK - ${res['ts'] ?? ''}' : 'Failed';
      _loading = false;
    });
  }

  Future<void> _generateHash() async {
    if (_pin.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final res = await _api.get('hashPin', query: {'pin': _pin.text.trim()});
    if (!mounted) return;
    setState(() {
      _hash = (res['pin_hash'] ?? '').toString();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Backend Utility', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _loading ? null : _checkHealth, icon: const Icon(Icons.health_and_safety), label: const Text('Check API Health')),
          const SizedBox(height: 8),
          Text('Health: $_health'),
          const Divider(height: 28),
          const Text('PIN Hash Generator', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _pin, obscureText: true, decoration: const InputDecoration(labelText: 'PIN')),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _loading ? null : _generateHash, icon: const Icon(Icons.password), label: const Text('Generate Hash')),
          const SizedBox(height: 8),
          SelectableText(_hash.isEmpty ? 'No hash generated' : _hash),
          const SizedBox(height: 12),
          const Text('Copy this hash into users_roles.pin_hash for secure login.', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
