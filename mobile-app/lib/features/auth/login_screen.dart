import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  Future<GoogleSignInAccount?> _pickGoogleAccount() async {
    await GoogleAuthService.signOut();
    return GoogleAuthService.signInInteractive();
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);

    try {
      final account = await _pickGoogleAccount();

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

  Future<void> _openSignupRequest() async {
    setState(() => _loading = true);
    try {
      final account = await _pickGoogleAccount();
      if (!mounted) return;
      if (account == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google sign-in cancelled')));
        setState(() => _loading = false);
        return;
      }

      final nameCtrl = TextEditingController(text: account.displayName ?? '');
      final phoneCtrl = TextEditingController();
      String requestedRole = 'VIEWER';

      final submit = await showDialog<bool>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: const Text('Sign Up Request'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Gmail: ${account.email}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Full Name'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: requestedRole,
                        decoration: const InputDecoration(labelText: 'Requested Role'),
                        items: const [
                          DropdownMenuItem(value: 'VIEWER', child: Text('VIEWER')),
                          DropdownMenuItem(value: 'FIELD_USER', child: Text('FIELD_USER')),
                          DropdownMenuItem(value: 'ACCOUNTANT', child: Text('ACCOUNTANT')),
                        ],
                        onChanged: (v) => setStateDialog(() => requestedRole = v ?? 'VIEWER'),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
                ],
              );
            },
          );
        },
      );

      if (!mounted) return;
      if (submit != true) {
        setState(() => _loading = false);
        return;
      }

      final res = await _api.post('signupRequest', {
        'payload': {
          'email': account.email.trim().toLowerCase(),
          'name': nameCtrl.text.trim().isEmpty ? (account.displayName ?? 'New User') : nameCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          'requested_role': requestedRole,
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${res['message'] ?? (res['ok'] == true ? 'Request submitted' : 'Request failed')}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _useTemporaryToken() async {
    setState(() => _loading = true);
    try {
      final account = await _pickGoogleAccount();
      if (!mounted) return;
      if (account == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google sign-in cancelled')));
        setState(() => _loading = false);
        return;
      }

      final tokenCtrl = TextEditingController();
      final submitted = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Use Temporary Reset Token'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Gmail: ${account.email}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                TextField(
                  controller: tokenCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Temporary Token'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apply')),
            ],
          );
        },
      );

      if (!mounted) return;
      if (submitted != true) {
        setState(() => _loading = false);
        return;
      }

      final token = tokenCtrl.text.trim().toUpperCase();
      if (token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Token is required')));
        setState(() => _loading = false);
        return;
      }

      final resetRes = await _api.post('consumeTempResetToken', {
        'payload': {
          'email': account.email.trim().toLowerCase(),
          'token': token,
        }
      });

      if (!mounted) return;
      if (resetRes['ok'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${resetRes['message'] ?? resetRes['error'] ?? 'Token verification failed'}')),
        );
        setState(() => _loading = false);
        return;
      }

      final loginRes = await _api.post('login', {'email': account.email.trim().toLowerCase()});
      if (!mounted) return;
      if (loginRes['ok'] == true) {
        final user = SessionUser.fromMap((loginRes['data'] ?? {}) as Map<String, dynamic>);
        SessionService.setUser(user);
        await SessionService.saveOfflineCredential(
          email: account.email.trim().toLowerCase(),
          googleId: account.id.trim(),
          user: user,
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access reset successful. Logged in.')));
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loginRes['message'] ?? loginRes['error'] ?? 'Login failed after reset'}')),
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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _openSignupRequest,
                      icon: const Icon(Icons.how_to_reg),
                      label: const Text('Sign Up Request'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _loading ? null : _useTemporaryToken,
                      icon: const Icon(Icons.password),
                      label: const Text('Use Temporary Reset Token'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Login needs approved Gmail (status: APPROVED). New users must submit sign-up request first.',
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
