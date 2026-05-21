import 'package:flutter/material.dart';

import '../../shared/models/session_user.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _api = ApiService();
  final _phone = TextEditingController();
  final _pin = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    if (_phone.text.trim().isEmpty || _pin.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone and PIN are required')));
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await _api.post('login', {
        'phone': _phone.text.trim(),
        'pin': _pin.text.trim(),
      });

      if (!mounted) return;
      if (res['ok'] == true) {
        final user = SessionUser.fromMap((res['data'] ?? {}) as Map<String, dynamic>);
        SessionService.setUser(user);
        await SessionService.saveOfflineCredential(_phone.text.trim(), _pin.text.trim(), user);
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      } else if (res['offline'] == true &&
          SessionService.loginFromOfflineCredential(_phone.text.trim(), _pin.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline login successful')));
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${res['message'] ?? res['error'] ?? 'Login failed'}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Madrasah ERP Lite', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
                  const SizedBox(height: 12),
                  TextField(controller: _pin, obscureText: true, decoration: const InputDecoration(labelText: 'PIN')),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _login,
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.login),
                      label: Text(_loading ? 'Logging in...' : 'Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
