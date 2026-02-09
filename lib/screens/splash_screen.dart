import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  /// Not used when you rely on named routes, but kept for flexibility
  final Widget? onFinished;
  const SplashScreen({super.key, this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();
  late final Animation<double> _scale =
  Tween<double>(begin: .3, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  late final Animation<double> _rotate =
  Tween<double>(begin: -.4, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (widget.onFinished != null) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => widget.onFinished!));
      } else {
        Navigator.pushReplacementNamed(context, '/onboard');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/eventra_logo.png'), context);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.teal.shade50,
    body: Center(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.rotate(
          angle: _rotate.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Image.asset('assets/images/eventra_logo.png', width: 220),
          ),
        ),
      ),
    ),
  );
}
