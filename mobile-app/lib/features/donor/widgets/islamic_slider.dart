import 'dart:async';
import 'package:flutter/material.dart';

const _slides = [
  _Slide(
    arabic: 'وَأَقِيمُواْ الصَّلاَةَ وَآتُواْ الزَّكَاةَ وَمَا تُقَدِّمُواْ لِأَنفُسِكُم مِّنْ خَيْرٍ تَجِدُوهُ عِندَ اللّهِ',
    bangla: 'নামায কায়েম করো, যাকাত আদায় করো, এবং নিজেদের জন্য যা কল্যাণ পাঠাবে তা আল্লাহর কাছে পাবে।',
    source: 'সূরা বাকারাহ ২:১১০',
  ),
  _Slide(
    arabic: 'مَن ذَا الَّذِي يُقْرِضُ اللَّهَ قَرْضًا حَسَنًا فَيُضَاعِفَهُ لَهُ وَلَهُ أَجْرٌ كَرِيمٌ',
    bangla: 'কে আল্লাহকে উত্তম ঋণ দেবে, তিনি তা তার জন্য বহুগুণে বৃদ্ধি করবেন এবং তার জন্য রয়েছে সম্মানজনক পুরস্কার।',
    source: 'সূরা হাদীদ ৫৭:১১',
  ),
  _Slide(
    arabic: 'إِنَّ الْمُصَّدِّقِينَ وَالْمُصَّدِّقَاتِ وَأَقْرَضُوا اللَّهَ قَرْضًا حَسَنًا يُضَاعَفُ لَهُمْ',
    bangla: 'যে পুরুষ ও মহিলারা সাদাকাহ প্রদান করে এবং আল্লাহকে উত্তম ঋণ দেয়, তাদের পুরস্কার বহুগুণে বাড়িয়ে দেওয়া হবে।',
    source: 'সূরা হাদীদ ৫৭:১৮',
  ),
  _Slide(
    arabic: '',
    bangla: '"সদকা কখনো সম্পদ কমায় না।"',
    source: 'হাদীস — সহীহ মুসলিম',
    isHadith: true,
  ),
  _Slide(
    arabic: '',
    bangla: '"তোমাদের মধ্যে সেই উত্তম যে মানুষের সবচেয়ে বেশি উপকার করে।"',
    source: 'হাদীস — আল-মুজামুল আওসাত',
    isHadith: true,
  ),
];

class _Slide {
  final String arabic;
  final String bangla;
  final String source;
  final bool isHadith;
  const _Slide({
    required this.arabic,
    required this.bangla,
    required this.source,
    this.isHadith = false,
  });
}

class IslamicSlider extends StatefulWidget {
  final double height;
  const IslamicSlider({super.key, this.height = 160});

  @override
  State<IslamicSlider> createState() => _IslamicSliderState();
}

class _IslamicSliderState extends State<IslamicSlider> {
  final _controller = PageController();
  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      final next = (_page + 1) % _slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary.withValues(alpha: 0.85), cs.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) {
                final s = _slides[i];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (s.arabic.isNotEmpty)
                        Text(
                          s.arabic,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onPrimary.withValues(alpha: 0.9),
                            fontFamily: 'serif',
                            height: 1.8,
                          ),
                        ),
                      if (s.arabic.isNotEmpty) const SizedBox(height: 6),
                      Text(
                        s.bangla,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onPrimary,
                          fontWeight: s.isHadith ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '— ${s.source}',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onPrimary.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _page == i ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: cs.onPrimary.withValues(alpha: _page == i ? 1.0 : 0.4),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}
