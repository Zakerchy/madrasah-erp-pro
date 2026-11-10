import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_lang.dart';
import '../../shared/constants/app_routes.dart';
import '../../shared/models/session_user.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/org_settings_service.dart';
import '../../shared/widgets/org_logo.dart';
import '../donor/donor_login_screen.dart';
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
  void initState() {
    super.initState();
    OrgSettings.load().then((_) { if (mounted) setState(() {}); });
  }

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
          SnackBar(content: Text(AppLang.t('অফলাইন লগইন সফল', 'Offline login successful'))),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
      } else {
        _showError(res['message'] ?? res['error'] ?? AppLang.t('লগইন ব্যর্থ হয়েছে', 'Login failed'));
      }
    } catch (e) {
      if (mounted) _showError('${AppLang.t('ত্রুটি', 'Error')}: $e');
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _showResetPinSheet() async {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    bool sending = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLang.t('পিন রিসেট', 'Reset PIN'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                AppLang.t('আপনার ইমেইল দিন। Admin-এর কাছে একটি রিসেট লিংক পাঠানো হবে।',
                    'Enter your email. A reset link will be sent to the Admin.'),
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppLang.t('ইমেইল', 'Email'),
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: sending
                    ? null
                    : () async {
                        final email = emailCtrl.text.trim().toLowerCase();
                        if (!email.contains('@')) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(AppLang.t('সঠিক ইমেইল দিন', 'Enter a valid email'))),
                          );
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        setS(() => sending = true);
                        final res = await _api.post(
                          'requestPinReset',
                          {'email': email},
                          allowQueue: false,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(res['message'] ?? (res['ok'] == true
                                ? AppLang.t('রিসেট লিংক পাঠানো হয়েছে', 'Reset link sent')
                                : AppLang.t('ব্যর্থ হয়েছে', 'Failed'))),
                            backgroundColor: res['ok'] == true
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: sending
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('রিসেট লিংক পাঠান'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final teal = scheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: AppLang.t('হোমে ফিরুন', 'Back to home'),
          onPressed: () => Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.landing, (route) => false),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: scheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    // Logo / Title
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: teal.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(color: teal.withValues(alpha: 0.35)),
                        ),
                        child: const ClipOval(child: OrgLogo(size: 80)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      OrgSettings.nameBn,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: teal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLang.t('আস-সালামু আলাইকুম', 'As-salamu alaikum'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email field
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: AppLang.t('ইমেইল', 'Email'),
                        hintText: 'example@gmail.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) return AppLang.t('ইমেইল দিন', 'Enter email');
                        if (!val.contains('@')) return AppLang.t('সঠিক ইমেইল দিন', 'Enter a valid email');
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
                        labelText: AppLang.t('পিন', 'PIN'),
                        hintText: AppLang.t('৪-৬ সংখ্যার পিন', '4-6 digit PIN'),
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
                        if (val.isEmpty) return AppLang.t('পিন দিন', 'Enter PIN');
                        if (val.length < 4) return AppLang.t('পিন কমপক্ষে ৪ সংখ্যার', 'PIN must be at least 4 digits');
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Forgot PIN
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _showResetPinSheet,
                        child: Text(AppLang.t('পিন ভুলে গেছেন?', 'Forgot PIN?')),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Login button
                    FilledButton(
                      onPressed: _loading ? null : _login,
                      style: ButtonStyle(
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(vertical: 16),
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.disabled)) {
                            return teal.withValues(alpha: 0.75);
                          }
                          return teal;
                        }),
                        foregroundColor: const WidgetStatePropertyAll(Colors.white),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_loading) ...[
                            const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            _loading
                                ? AppLang.t('প্রবেশ করা হচ্ছে...', 'Signing in...')
                                : AppLang.t('প্রবেশ করুন', 'Sign in'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Help text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Text(
                        AppLang.t(
                          'নতুন ব্যবহারকারী হতে চাইলে Admin-এর সাথে যোগাযোগ করুন। Admin আপনার ইমেইল ও পিন সেট করে দেবেন।',
                          'To become a new user, contact the Admin. The Admin will set up your email and PIN.',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: scheme.onSurface),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DonorLoginScreen()),
                      ),
                      icon: const Icon(Icons.volunteer_activism, size: 18),
                      label: Text(AppLang.t('দানকারী পোর্টাল', 'Donor Portal')),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
