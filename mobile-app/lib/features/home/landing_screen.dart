import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../shared/services/org_settings_service.dart';
import '../auth/login_screen.dart';
import '../donor/donor_login_screen.dart';

/// Public home page — the first thing any visitor sees, no login needed.
/// Shows the madrasah's real identity (logo, name, about/mission) and
/// offers two doors in: the donor portal (public signup/donate) and a
/// small, unobtrusive staff-login link.
///
/// Palette is deliberately separate from the app's internal dark theme:
/// white/cream, deep green and gold — the same tones as the official seal —
/// since this page is the public "shop front", not an app screen.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  static const _green = Color(0xFF0E4D3A);
  static const _greenDark = Color(0xFF083024);
  static const _gold = Color(0xFFC9A227);
  static const _goldLight = Color(0xFFE6C861);
  static const _cream = Color(0xFFFBF8F0);

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
    final about = OrgSettings.aboutBn.trim();

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Hero band: deep green, gold trim ────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_greenDark, _green],
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 34),
                    _GoldRing(
                      size: 128,
                      child: ClipOval(
                        child: Container(
                          color: Colors.white,
                          child: OrgSettings.logoUrl.isNotEmpty
                              ? Image.network(
                                  OrgSettings.logoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.mosque_rounded, size: 56, color: _green),
                                )
                              : const Icon(Icons.mosque_rounded, size: 56, color: _green),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      style: TextStyle(fontSize: 16, color: _goldLight, letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        OrgSettings.nameBn,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLang.t('আস-সালামু আলাইকুম ওয়া রাহমাতুল্লাহ', 'As-salamu alaykum wa rahmatullah'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _InfoPill(icon: Icons.calendar_today_rounded, text: AppLang.t('প্রতিষ্ঠাকাল ২০১২', 'Est. 2012')),
                        _InfoPill(icon: Icons.location_on_rounded, text: AppLang.t('পূর্ব নাসিরাবাদ, চট্টগ্রাম', 'East Nasirabad, Chattogram')),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // gold scalloped divider into the cream body
                    const _ScallopDivider(),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    children: [
                      // ── About / mission ──────────────────────────────────
                      _GoldBorderCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _green.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.auto_stories_rounded, color: _green, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  AppLang.t('আমাদের সম্পর্কে', 'About Us'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _greenDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              about.isNotEmpty ? about : _defaultAbout,
                              style: const TextStyle(fontSize: 14.5, height: 1.75, color: Color(0xFF3A3A3A)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Our pillars ──────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _PillarTile(
                              icon: Icons.menu_book_rounded,
                              title: AppLang.t('কুরআন-সুন্নাহ', 'Qur\'an & Sunnah'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PillarTile(
                              icon: Icons.favorite_rounded,
                              title: AppLang.t('নৈতিক গঠন', 'Moral Formation'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PillarTile(
                              icon: Icons.volunteer_activism_rounded,
                              title: AppLang.t('জনসেবা', 'Community Service'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Ayah ─────────────────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_green, _greenDark],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _gold, width: 1.2),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'وَأَقِيمُوا الصَّلَاةَ وَآتُوا الزَّكَاةَ وَمَا تُقَدِّمُوا لِأَنفُسِكُم مِّنْ خَيْرٍ تَجِدُوهُ عِندَ اللَّهِ',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _goldLight, fontSize: 16, height: 1.7),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              AppLang.t(
                                'নামায কায়েম করো, যাকাত আদায় করো, এবং নিজেদের জন্য যা কল্যাণ পাঠাবে তা আল্লাহর কাছে পাবে।',
                                'Establish prayer, give zakat, and whatever good you put forth for yourselves, you will find it with Allah.',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLang.t('— সূরা বাকারাহ, ২:১১০', '— Surah Al-Baqarah, 2:110'),
                              style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── CTAs ──────────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _openDonorPortal,
                          icon: const Icon(Icons.volunteer_activism_rounded),
                          label: Text(
                            AppLang.t('দান করুন / দানকারী পোর্টাল', 'Donate / Donor Portal'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: _gold, width: 1.2),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: _openStaffLogin,
                        icon: const Icon(Icons.admin_panel_settings_outlined, size: 18, color: _green),
                        label: Text(
                          AppLang.t('স্টাফ লগইন', 'Staff Login'),
                          style: const TextStyle(color: _green, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _defaultAbout =
      'আল-মদীনাতুল মুনাওওয়ারাহ্‌ কমপ্লেক্স ২০১২ সাল থেকে পূর্ব নাসিরাবাদ, চট্টগ্রামে একটি দ্বীনি শিক্ষা প্রতিষ্ঠান হিসেবে পরিচালিত হয়ে আসছে। '
      'আমাদের লক্ষ্য কুরআন-সুন্নাহর আলোকে শিক্ষার্থীদের নৈতিক, আত্মিক ও ধর্মীয় শিক্ষায় গড়ে তোলা। আপনাদের দান ও সহযোগিতা আমাদের এই দ্বীনি খেদমত '
      'অব্যাহত রাখতে সাহায্য করে — জাযাকাল্লাহু খাইরান।';
}

class _GoldRing extends StatelessWidget {
  final double size;
  final Widget child;
  const _GoldRing({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            _LandingScreenState._gold,
            _LandingScreenState._goldLight,
            _LandingScreenState._gold,
            _LandingScreenState._goldLight,
            _LandingScreenState._gold,
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: ClipOval(child: SizedBox(width: size - 14, height: size - 14, child: child)),
      ),
    );
  }
}

class _ScallopDivider extends StatelessWidget {
  const _ScallopDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: CustomPaint(
        size: const Size(double.infinity, 14),
        painter: _ScallopPainter(),
      ),
    );
  }
}

class _ScallopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _LandingScreenState._cream;
    final path = Path()..moveTo(0, 0);
    const scallopWidth = 20.0;
    final count = (size.width / scallopWidth).ceil();
    for (var i = 0; i < count; i++) {
      final x = i * scallopWidth;
      path.arcToPoint(
        Offset(x + scallopWidth, 0),
        radius: const Radius.circular(scallopWidth / 2),
        clockwise: false,
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _LandingScreenState._gold.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _LandingScreenState._goldLight),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _GoldBorderCard extends StatelessWidget {
  final Widget child;
  const _GoldBorderCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _LandingScreenState._gold.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: _LandingScreenState._greenDark.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PillarTile extends StatelessWidget {
  final IconData icon;
  final String title;
  const _PillarTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _LandingScreenState._gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _LandingScreenState._green, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _LandingScreenState._greenDark),
          ),
        ],
      ),
    );
  }
}
