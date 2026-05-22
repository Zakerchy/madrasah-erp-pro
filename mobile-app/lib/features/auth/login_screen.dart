import 'package:flutter/material.dart';

import '../../shared/models/session_user.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/google_auth_service.dart';
import '../../shared/services/session_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _api = ApiService();
  bool _loading = false;

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);

    try {
      await GoogleAuthService.signOut();
      final account = await GoogleAuthService.signInInteractive();

      if (!mounted) return;
      if (account == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google sign-in cancelled')));
        setState(() => _loading = false);
        return;
      }

      final email = account.email.trim().toLowerCase();
      final googleId = account.id.trim();

      final res = await _api.post('login', {
        'email': email,
      });

      if (!mounted) return;

      if (res['ok'] == true) {
        final user = SessionUser.fromMap((res['data'] ?? {}) as Map<String, dynamic>);
        SessionService.setUser(user);
        await SessionService.saveOfflineCredential(
          email: email,
          googleId: googleId,
          user: user,
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome ${user.name}')));
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      } else if (res['offline'] == true && SessionService.loginFromOfflineCredential(email: email, googleId: googleId)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline login successful')));
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${res['message'] ?? res['error'] ?? 'Login failed'}')),
        );
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
                  const SizedBox(height: 8),
                  const Text(
                    'Use your approved Gmail account for role-based login and sync authorization.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _loginWithGoogle,
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.account_circle),
                      label: Text(_loading ? 'Signing in...' : 'Sign in with Google'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Only Gmail accounts listed in users_roles (active=TRUE) can login.',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
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
