import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import 'donor_api.dart';
import 'donor_session.dart';
import 'donor_home_screen.dart';
import 'donor_signup_screen.dart';
import 'widgets/islamic_slider.dart';

class DonorLoginScreen extends StatefulWidget {
  const DonorLoginScreen({super.key});

  @override
  State<DonorLoginScreen> createState() => _DonorLoginScreenState();
}

class _DonorLoginScreenState extends State<DonorLoginScreen> {
  final _phone = TextEditingController();
  final _pin = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    final phone = _phone.text.trim();
    final pin = _pin.text.trim();
    if (phone.isEmpty || pin.isEmpty) {
      setState(() => _error = AppLang.t('ফোন ও পিন দিন', 'Enter phone and PIN'));
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await DonorApi.login(phone, pin);
      if (res['ok'] == true) {
        await DonorSession.save(
          res['donor_id'] as String,
          res['donor_token'] as String,
          Map<String, dynamic>.from(res['donor'] as Map),
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DonorHomeScreen()),
        );
      } else {
        setState(() => _error = res['message'] as String? ?? AppLang.t('লগইন ব্যর্থ', 'Login failed'));
      }
    } catch (e) {
      setState(() => _error = AppLang.t('সংযোগ ত্রুটি', 'Connection error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Logo / title
              Column(
                children: [
                  Icon(Icons.mosque_rounded, size: 56, color: cs.primary),
                  const SizedBox(height: 8),
                  Text(
                    AppLang.t('দানকারী পোর্টাল', 'Donor Portal'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  Text(
                    AppLang.t('আপনার অনুদানের পূর্ণ স্বচ্ছতা', 'Full transparency of your donations'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const IslamicSlider(height: 150),
              const SizedBox(height: 24),

              // Fields
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: AppLang.t('মোবাইল নম্বর', 'Mobile Number'),
                  prefixIcon: const Icon(Icons.phone),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: AppLang.t('পিন (৪-৬ সংখ্যা)', 'PIN (4-6 digits)'),
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: cs.error, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _login,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(AppLang.t('লগইন করুন', 'Login')),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DonorSignupScreen()),
                ),
                child: Text(AppLang.t('নতুন রেজিস্ট্রেশন করুন', 'New Registration')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
