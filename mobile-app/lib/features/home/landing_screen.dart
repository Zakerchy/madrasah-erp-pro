import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../core/theme.dart';
import '../../shared/constants/fund_types.dart';
import '../../shared/services/org_settings_service.dart';
import '../../shared/services/pwa_runtime_service.dart';
import '../../shared/widgets/org_logo.dart';
import '../auth/login_screen.dart';
import '../donor/donor_api.dart';
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
  static const _green = AppBrand.green;
  static const _greenDark = AppBrand.greenDark;
  static const _gold = AppBrand.gold;
  static const _goldLight = AppBrand.goldLight;
  static const _cream = AppBrand.cream;

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

  void _openDonorPortalForFund(String fundKey) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DonorLoginScreen(initialFundType: fundKey)),
    );
  }

  void _openStaffLogin() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _openParticipationForm({String? fundKey}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ParticipationSheet(initialFundKey: fundKey),
    );
  }

  Future<void> _installWebApp() async {
    final opened = await pwaRuntimeService.promptInstall();
    if (opened || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pwaRuntimeService.installHelpMessage(isEnglish: AppLang.isEnglish.value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final about = OrgSettings.aboutBn.trim();

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: logo left, name centered, portal/login on the right ──
            _TopBar(
              onDonorPortal: _openDonorPortal,
              onStaffLogin: _openStaffLogin,
              onInstall: _installWebApp,
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ── Hero band: deep green, gold trim ────────────────────
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
                          const SizedBox(height: 26),
                          const Text(
                            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                            style: TextStyle(fontSize: 16, color: _goldLight, letterSpacing: 0.6),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppLang.t('আস-সালামু আলাইকুম ওয়া রাহমাতুল্লাহ', 'As-salamu alaykum wa rahmatullah'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              _InfoPill(icon: Icons.calendar_today_rounded, text: AppLang.t('প্রতিষ্ঠাকাল ২০১২', 'Est. 2012')),
                              _InfoPill(icon: Icons.location_on_rounded, text: AppLang.t('পূর্ব নাসিরাবাদ, চট্টগ্রাম', 'East Nasirabad, Chattogram')),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: const _VerseSlider(),
                            ),
                          ),
                          const SizedBox(height: 28),
                          // gold scalloped divider into the cream body
                          const _ScallopDivider(),
                        ],
                      ),
                    ),

                    // ── Our ongoing projects: donate or apply to participate ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLang.t('আমাদের চলমান প্রকল্পসমূহ', 'Our Ongoing Projects'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _greenDark),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLang.t(
                              'যেকোনো খাতে সরাসরি দান করুন, অথবা প্রকল্পে অংশগ্রহণের আবেদন করুন',
                              'Donate directly to any fund, or apply to participate in a project',
                            ),
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF5A5A5A)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 176,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: FundTypes.donorVisible.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final fund = FundTypes.donorVisible[i];
                          return _ProjectCard(
                            fund: fund,
                            onDonate: () => _openDonorPortalForFund(fund.key),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: OutlinedButton.icon(
                        onPressed: () => _openParticipationForm(),
                        icon: const Icon(Icons.how_to_reg_rounded, size: 18, color: _green),
                        label: Text(
                          AppLang.t('প্রকল্পে অংশগ্রহণের আবেদন করুন', 'Apply to Participate in a Project'),
                          style: const TextStyle(color: _green, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          side: const BorderSide(color: _gold, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
          ],
        ),
      ),
    );
  }

  static const _defaultAbout =
      'আল-মদীনাতুল মুনাওওয়ারাহ্‌ কমপ্লেক্স ২০১২ সাল থেকে পূর্ব নাসিরাবাদ, চট্টগ্রামে একটি দ্বীনি শিক্ষা প্রতিষ্ঠান হিসেবে পরিচালিত হয়ে আসছে। '
      'আমাদের লক্ষ্য কুরআন-সুন্নাহর আলোকে শিক্ষার্থীদের নৈতিক, আত্মিক ও ধর্মীয় শিক্ষায় গড়ে তোলা। আপনাদের দান ও সহযোগিতা আমাদের এই দ্বীনি খেদমত '
      'অব্যাহত রাখতে সাহায্য করে — জাযাকাল্লাহু খাইরান।';
}

/// Sticky top bar: logo on the left, org name centered, a portal/login
/// dropdown on the right — the public page's quick-access nav.
class _TopBar extends StatelessWidget {
  final VoidCallback onDonorPortal;
  final VoidCallback onStaffLogin;
  final VoidCallback onInstall;
  const _TopBar({required this.onDonorPortal, required this.onStaffLogin, required this.onInstall});

  static const _green = _LandingScreenState._green;
  static const _greenDark = _LandingScreenState._greenDark;
  static const _gold = _LandingScreenState._gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _gold.withValues(alpha: 0.35))),
      ),
      child: Row(
        children: [
          const _GoldRing(
            size: 42,
            child: ClipOval(child: OrgLogo(size: 34)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                OrgSettings.nameBn,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _greenDark),
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: pwaRuntimeService.standaloneMode,
            builder: (_, standalone, __) => ValueListenableBuilder<bool>(
              valueListenable: pwaRuntimeService.installAvailable,
              builder: (_, installAvailable, __) {
                if (standalone || !installAvailable) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: onInstall,
                    icon: const Icon(Icons.install_mobile_rounded, size: 18, color: _green),
                    label: Text(
                      AppLang.t('অ্যাপ ইনস্টল', 'Install App'),
                      style: const TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: _green.withValues(alpha: 0.07),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: _gold.withValues(alpha: 0.5)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                );
              },
            ),
          ),
          PopupMenuButton<int>(
            onSelected: (v) => v == 0 ? onDonorPortal() : onStaffLogin(),
            offset: const Offset(0, 46),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: _gold.withValues(alpha: 0.5)),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 0,
                child: Row(
                  children: [
                    const Icon(Icons.volunteer_activism_rounded, size: 18, color: _green),
                    const SizedBox(width: 10),
                    Text(AppLang.t('দানকারী পোর্টাল', 'Donor Portal')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined, size: 18, color: _green),
                    const SizedBox(width: 10),
                    Text(AppLang.t('স্টাফ লগইন', 'Staff Login')),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _gold.withValues(alpha: 0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_circle_outlined, size: 18, color: _green),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _green),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseSlide {
  final String arabic;
  final String bangla;
  final String source;
  const _VerseSlide({required this.arabic, required this.bangla, required this.source});
}

const _verseSlides = [
  _VerseSlide(
    arabic: 'وَأَقِيمُواْ الصَّلاَةَ وَآتُواْ الزَّكَاةَ وَمَا تُقَدِّمُواْ لِأَنفُسِكُم مِّنْ خَيْرٍ تَجِدُوهُ عِندَ اللّهِ',
    bangla: 'নামায কায়েম করো, যাকাত আদায় করো, এবং নিজেদের জন্য যা কল্যাণ পাঠাবে তা আল্লাহর কাছে পাবে।',
    source: 'সূরা বাকারাহ, ২:১১০',
  ),
  _VerseSlide(
    arabic: 'مَن ذَا الَّذِي يُقْرِضُ اللَّهَ قَرْضًا حَسَنًا فَيُضَاعِفَهُ لَهُ وَلَهُ أَجْرٌ كَرِيمٌ',
    bangla: 'কে আল্লাহকে উত্তম ঋণ দেবে, যা তিনি তার জন্য বহুগুণে বৃদ্ধি করে দেবেন এবং তার জন্য রয়েছে সম্মানজনক পুরস্কার।',
    source: 'সূরা হাদীদ, ৫৭:১১',
  ),
  _VerseSlide(
    arabic: 'إِنَّ الْمُصَّدِّقِينَ وَالْمُصَّدِّقَاتِ وَأَقْرَضُوا اللَّهَ قَرْضًا حَسَنًا يُضَاعَفُ لَهُمْ',
    bangla: 'যে পুরুষ ও নারীরা সাদাকাহ দেয় এবং আল্লাহকে উত্তম ঋণ দেয়, তাদের পুরস্কার বহুগুণে বাড়িয়ে দেওয়া হবে।',
    source: 'সূরা হাদীদ, ৫৭:১৮',
  ),
  _VerseSlide(
    arabic: '',
    bangla: '"সদকা কখনো সম্পদ কমায় না।"',
    source: 'হাদীস — সহীহ মুসলিম',
  ),
  _VerseSlide(
    arabic: '',
    bangla: '"তোমাদের মধ্যে উত্তম সেই, যে মানুষের সবচেয়ে বেশি উপকার করে।"',
    source: 'হাদীস — আল-মুজামুল আওসাত',
  ),
];

/// Auto-rotating carousel of Qur'an/Hadith sayings about charity, styled to
/// match the landing page (white card, gold border, deep-green text) so it
/// reads as part of the same design language, not a bolted-on widget.
class _VerseSlider extends StatefulWidget {
  const _VerseSlider();

  @override
  State<_VerseSlider> createState() => _VerseSliderState();
}

class _VerseSliderState extends State<_VerseSlider> {
  static const _green = _LandingScreenState._green;
  static const _greenDark = _LandingScreenState._greenDark;
  static const _gold = _LandingScreenState._gold;

  final _controller = PageController();
  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % _verseSlides.length;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold, width: 1.2),
        boxShadow: [
          BoxShadow(color: _greenDark.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.format_quote_rounded, color: _gold.withValues(alpha: 0.7), size: 18),
              const SizedBox(width: 6),
              Text(
                AppLang.t('দান সম্পর্কে', 'On Charity'),
                style: const TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.4),
              ),
            ],
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _verseSlides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) {
                final s = _verseSlides[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (s.arabic.isNotEmpty)
                        Text(
                          s.arabic,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontSize: 14, color: _green, fontFamily: 'serif', height: 1.7, fontWeight: FontWeight.w600),
                        ),
                      if (s.arabic.isNotEmpty) const SizedBox(height: 8),
                      Text(
                        s.bangla,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF3A3A3A), height: 1.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '— ${s.source}',
                        style: TextStyle(fontSize: 11, color: _gold.withValues(alpha: 0.9), fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _verseSlides.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _page == i ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: _page == i ? _green : _gold.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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

IconData _fundIcon(String key) {
  switch (key) {
    case 'ZAKAT':
      return Icons.account_balance_rounded;
    case 'TALEBE_ELM':
      return Icons.school_rounded;
    case 'YATIM':
      return Icons.family_restroom_rounded;
    case 'BIA':
      return Icons.favorite_rounded;
    case 'EID':
      return Icons.card_giftcard_rounded;
    case 'IFTAR':
      return Icons.restaurant_rounded;
    case 'FITRA':
      return Icons.volunteer_activism_rounded;
    case 'LIBRARY':
      return Icons.menu_book_rounded;
    case 'WATER':
      return Icons.water_drop_rounded;
    default:
      return Icons.mosque_rounded;
  }
}

/// One project/fund card in the horizontal "Our Ongoing Projects" strip.
class _ProjectCard extends StatelessWidget {
  final FundType fund;
  final VoidCallback onDonate;
  const _ProjectCard({required this.fund, required this.onDonate});

  static const _green = _LandingScreenState._green;
  static const _greenDark = _LandingScreenState._greenDark;
  static const _gold = _LandingScreenState._gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 172,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(color: _greenDark.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _green.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(_fundIcon(fund.key), color: _green, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            AppLang.t(fund.labelBn, fund.labelEn),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: _greenDark, height: 1.3),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              fund.descBn,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B6B6B), height: 1.3),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: onDonate,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                AppLang.t('দান করুন', 'Donate'),
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet: a visitor applies to participate in / support a project.
/// Public — no donor login needed, just captures the lead for admin follow-up.
class _ParticipationSheet extends StatefulWidget {
  final String? initialFundKey;
  const _ParticipationSheet({this.initialFundKey});

  @override
  State<_ParticipationSheet> createState() => _ParticipationSheetState();
}

class _ParticipationSheetState extends State<_ParticipationSheet> {
  static const _green = _LandingScreenState._green;
  static const _greenDark = _LandingScreenState._greenDark;
  static const _gold = _LandingScreenState._gold;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  String? _fundKey;
  bool _loading = false;
  String? _error;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _fundKey = widget.initialFundKey;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _error = AppLang.t('নাম ও মোবাইল নম্বর দিন', 'Enter name and mobile number'));
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await DonorApi.submitParticipationRequest({
        'name': name,
        'phone': phone,
        'email': _email.text.trim(),
        'fund_interest': _fundKey ?? '',
        'message': _message.text.trim(),
      });
      if (!mounted) return;
      if (res['ok'] == true) {
        setState(() => _done = true);
      } else {
        setState(() => _error = res['message'] as String? ?? AppLang.t('ত্রুটি হয়েছে', 'Something went wrong'));
      }
    } catch (e) {
      setState(() => _error = AppLang.t('সংযোগ ত্রুটি', 'Connection error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: _gold, width: 1.4)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SingleChildScrollView(
          child: _done ? _buildDone(context) : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildDone(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        const Icon(Icons.check_circle_rounded, color: _green, size: 48),
        const SizedBox(height: 12),
        Text(
          AppLang.t('জাযাকাল্লাহু খাইরান!', 'JazakAllahu Khayran!'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _greenDark),
        ),
        const SizedBox(height: 6),
        Text(
          AppLang.t(
            'আপনার আবেদন গ্রহণ করা হয়েছে। অ্যাডমিন শীঘ্রই যোগাযোগ করবেন।',
            'Your application has been received. The admin will contact you soon.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Color(0xFF5A5A5A)),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(backgroundColor: _green),
            child: Text(AppLang.t('বন্ধ করুন', 'Close')),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: _gold.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
          ),
        ),
        Text(
          AppLang.t('প্রকল্পে অংশগ্রহণের আবেদন', 'Apply to Participate'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _greenDark),
        ),
        const SizedBox(height: 4),
        Text(
          AppLang.t(
            'আপনার তথ্য দিন, অ্যাডমিন আপনার সাথে যোগাযোগ করবেন।',
            'Share your details and the admin will get in touch.',
          ),
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          decoration: InputDecoration(
            labelText: AppLang.t('নাম *', 'Name *'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: AppLang.t('মোবাইল নম্বর *', 'Mobile Number *'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: AppLang.t('ইমেইল (ঐচ্ছিক)', 'Email (optional)'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _fundKey,
          decoration: InputDecoration(
            labelText: AppLang.t('আগ্রহের প্রকল্প (ঐচ্ছিক)', 'Project of interest (optional)'),
            border: const OutlineInputBorder(),
          ),
          items: FundTypes.donorVisible
              .map((f) => DropdownMenuItem(value: f.key, child: Text(AppLang.t(f.labelBn, f.labelEn))))
              .toList(),
          onChanged: (v) => setState(() => _fundKey = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _message,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: AppLang.t('বার্তা (ঐচ্ছিক)', 'Message (optional)'),
            border: const OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: _gold, width: 1.1),
              ),
            ),
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(AppLang.t('আবেদন পাঠান', 'Submit Application'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
