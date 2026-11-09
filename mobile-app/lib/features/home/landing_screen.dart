import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../shared/services/org_settings_service.dart';
import '../auth/login_screen.dart';
import '../donor/donor_login_screen.dart';

/// Public home page — the first thing any visitor sees, no login needed.
/// Shows the madrasah's real identity (logo, name, about/mission) and
/// offers two doors in: the donor portal (public signup/donate) and a
/// small, unobtrusive staff-login link.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  static const _gold = Color(0xFFD4AF6A);

  @override
  void initState() {
    super.initState();
    OrgSettings.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openDonorPortal() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DonorLoginScreen()));
  }

  void _openStaffLogin() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final about = OrgSettings.aboutBn.trim();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
              child: Column(
                children: [
                  // ── Hero: logo, name, Islamic greeting ──────────────────
                  Container(
                    width: 112,
                    height: 112,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [cs.primary, _gold, cs.primary],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF08111F)),
                      child: ClipOval(
                        child: OrgSettings.logoUrl.isNotEmpty
                            ? Image.network(
                                OrgSettings.logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(Icons.mosque_rounded, size: 52, color: cs.primary),
                              )
                            : Icon(Icons.mosque_rounded, size: 52, color: cs.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                    style: TextStyle(fontSize: 15, color: _gold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    OrgSettings.nameBn,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLang.t('আস-সালামু আলাইকুম ওয়া রাহমাতুল্লাহ', 'As-salamu alaykum wa rahmatullah'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),

                  const SizedBox(height: 28),

                  // ── About / mission ──────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_stories_rounded, color: _gold, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              AppLang.t('আমাদের সম্পর্কে', 'About Us'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          about.isNotEmpty ? about : _defaultAbout,
                          style: const TextStyle(fontSize: 14, height: 1.7, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── CTAs ──────────────────────────────────────────────────
                  FilledButton.icon(
                    onPressed: _openDonorPortal,
                    icon: const Icon(Icons.volunteer_activism_rounded),
                    label: Text(AppLang.t('দান করুন / দানকারী পোর্টাল', 'Donate / Donor Portal')),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),

                  const SizedBox(height: 28),
                  TextButton.icon(
                    onPressed: _openStaffLogin,
                    icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                    label: Text(AppLang.t('স্টাফ লগইন', 'Staff Login')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _defaultAbout =
      'আল-মদীনাতুল মুনাওওয়ারাহ্‌ কমপ্লেক্স একটি দ্বীনি শিক্ষা প্রতিষ্ঠান, যার লক্ষ্য কুরআন-সুন্নাহর আলোকে '
      'ছাত্রদের নৈতিক ও ধর্মীয় শিক্ষায় গড়ে তোলা। আপনাদের দান ও সহযোগিতা আমাদের এই দ্বীনি খেদমত চালিয়ে যেতে '
      'সাহায্য করে — জাযাকাল্লাহু খাইরান।';
}
