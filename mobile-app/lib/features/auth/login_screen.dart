import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/models/session_user.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _api = ApiService();
  bool _loading = false;
  bool _pinVisible = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final email = _emailCtrl.text.trim().toLowerCase();
    final pin = _pinCtrl.text.trim();
    final pinHash = ApiService.hashPin(pin);

    try {
      final res = await _api.post('login', {
        'email': email,
        'pin_hash': pinHash,
      }, allowQueue: false);

      if (!mounted) return;

      if (res['ok'] == true) {
        final user = SessionUser.fromMap((res['data'] ?? {}) as Map<String, dynamic>);
        SessionService.setUser(user);
        await SessionService.saveOfflineCredential(
          email: email,
          pinHash: pinHash,
          user: user,
        );
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
      } else if (res['offline'] == true &&
          SessionService.loginFromOfflineCredential(email: email, pinHash: pinHash)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('অফলাইন লগইন সফল')),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
      } else {
        _showError(res['message'] ?? res['error'] ?? 'লগইন ব্যর্থ হয়েছে');
      }
    } catch (e) {
      if (mounted) _showError('ত্রুটি: $e');
    }

    if (mounted) setState(() => _loading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teal = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo / Title
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'মাদ্রাসা ERP',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: teal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'আস-সালামু আলাইকুম',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email field
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'ইমেইল',
                        hintText: 'example@gmail.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) return 'ইমেইল দিন';
                        if (!val.contains('@')) return 'সঠিক ইমেইল দিন';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // PIN field
                    TextFormField(
                      controller: _pinCtrl,
                      obscureText: !_pinVisible,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: InputDecoration(
                        labelText: 'পিন',
                        hintText: '৪-৬ সংখ্যার পিন',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_pinVisible ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _pinVisible = !_pinVisible),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) return 'পিন দিন';
                        if (val.length < 4) return 'পিন কমপক্ষে ৪ সংখ্যার';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Login button
                    FilledButton(
                      onPressed: _loading ? null : _login,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'প্রবেশ করুন',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Help text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Text(
                        'নতুন ব্যবহারকারী হতে চাইলে Admin-এর সাথে যোগাযোগ করুন। Admin আপনার ইমেইল ও পিন সেট করে দেবেন।',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
