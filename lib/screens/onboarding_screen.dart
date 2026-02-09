import 'dart:async';
import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
///  SINGLE‑FILE ONBOARDING  (no external widget imports)
/// ─────────────────────────────────────────────────────────────
///  Widgets in this file:
///   • OnboardingScreen  (main screen)
///   • _OnboardPage      (one slide)
///   • _GradientButton   (CTA button)
///   • _DotIndicator     (animated dots)
///   • _SkipButton       (“Skip” link)
/// ─────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  /// Callback that returns the real home/dashboard widget
  final Widget Function() goToHome;
  const OnboardingScreen({super.key, required this.goToHome});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;
  Timer? _timer;

  /* ---------------- 3 computer‑themed slides ---------------- */
  static const _slides = [
    _OnboardPage(
      image:
      'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=800&q=60',
      title: 'Discover Tech Events',
      desc: 'Hackathons, coding fests and more\nin one central place.',
    ),
    _OnboardPage(
      image:
      'https://images.unsplash.com/photo-1535223289827-42f1e9919769?auto=format&fit=crop&w=800&q=60',
      title: 'Register Instantly',
      desc: 'Join with one tap • QR check‑in •\nNo more paper forms.',
    ),
    _OnboardPage(
      image:
      'https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=800&q=60',
      title: 'Earn Badges & Rewards',
      desc: 'Track streaks, collect points\nand climb the leaderboard.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer =
        Timer.periodic(const Duration(seconds: 4), (_) => _next(auto: true));
  }

  /* Auto‑advance or manual next */
  void _next({bool auto = false}) {
    final next = (_page + 1) % _slides.length;
    _ctrl.animateToPage(next,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    if (!auto) _timer?.cancel(); // stop auto‑scroll after manual tap
  }

  /* Navigation helpers */
  void _goLogin() {
    _timer?.cancel();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _goHome() {
    _timer?.cancel();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => widget.goToHome()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(children: [
      /* ---------- Slides ---------- */
      Expanded(
        child: PageView.builder(
          controller: _ctrl,
          itemCount: _slides.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => _slides[i],
        ),
      ),

      /* ---------- Dots ---------- */
      _DotIndicator(count: _slides.length, index: _page),
      const SizedBox(height: 32),

      /* ---------- CTA button ---------- */
      _GradientButton(
        text:
        _page == _slides.length - 1 ? 'Login / Signup' : 'Login / Signup',
        width: 200,
        onPressed: _page == _slides.length - 1 ? _goLogin : _goLogin,
      ),
      const SizedBox(height: 12),

      /* ---------- Skip ---------- */
      // _SkipButton(onPressed: _goHome),
      // const SizedBox(height: 24),
    ]),
  );
}

/// ─────────────────────────────────────────────────────────────
///  PRIVATE WIDGETS  (underscored so they stay local)
/// ─────────────────────────────────────────────────────────────

/* A single slide */
class _OnboardPage extends StatelessWidget {
  final String image, title, desc;
  const _OnboardPage(
      {required this.image, required this.title, required this.desc});

  bool get _net => image.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final imgH = MediaQuery.of(context).size.height * .35;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Column(children: [
        /* Illustration */
        Container(
            height: imgH,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: DecorationImage(
                    fit: BoxFit.cover,
                    image: _net
                        ? NetworkImage(image)
                        : AssetImage(image) as ImageProvider))),
        const SizedBox(height: 40),
        /* Title */
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C2E5B))),
        const SizedBox(height: 16),
        /* Description */
        Text(desc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black54)),
      ]),
    );
  }
}

/* Gradient button */
class _GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double width;
  const _GradientButton(
      {required this.text, required this.onPressed, this.width = double.infinity});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: DecoratedBox(
      decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [
            Color(0xFF1C2E5B),
            Color(0xFF147B8E),
            Color(0xFF2BB673)
          ]),
          borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(text,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    ),
  );
}

/* Dots row */
class _DotIndicator extends StatelessWidget {
  final int count;
  final int index;
  const _DotIndicator({required this.count, required this.index});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
        count,
            (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == i ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
              color: index == i
                  ? Colors.teal
                  : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(12)),
        )),
  );
}

/* Skip link */
// class _SkipButton extends StatelessWidget {
//   final VoidCallback onPressed;
//   const _SkipButton({required this.onPressed});
//
//   @override
//   Widget build(BuildContext context) => Align(
//     alignment: Alignment.centerRight,
//     child: Padding(
//       padding: const EdgeInsets.only(right: 24),
//       child: TextButton(
//         onPressed: onPressed,
//         child: const Text('Skip', style: TextStyle(color: Colors.black)),
//       ),
//     ),
//   );
// }
