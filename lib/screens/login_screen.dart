import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/streak_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool _obscurePassword = true;

  final emailRx = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
  final passRx = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@#_]).{6,}$');

  final _auth = AuthService();

  // ───────── LOGIN ─────────
  Future<void> _login() async {
    final email = emailC.text.trim();
    final pw = passC.text.trim();

    if (!emailRx.hasMatch(email)) {
      return _alert('Invalid Email', 'Only @gmail.com addresses are allowed.');
    }
    if (!passRx.hasMatch(pw)) {
      return _alert(
        'Invalid Password',
        'Include a letter, a number and one of @ # _. Minimum 6 characters.',
      );
    }

    try {
      final user = await _auth.signIn(email, pw);
      if (user == null) {
        return _alert('Login failed', 'Wrong credentials');
      }

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final roleSnap = await userRef.get();
      final role = roleSnap.data()?['role'] ?? 'Participant';

      // --- NEW: centralised streak logic ---
      await StreakService.updateDailyStreak(user.uid);

      // Optional: keep simple present flag per day (not used by streak logic)
      final today = DateTime.now();
      final todayStr = today.toIso8601String().substring(0, 10);
      await userRef.collection('login_history').doc(todayStr).set({
        'present': true,
      }, SetOptions(merge: true));

      if (!mounted) return;

      // You can save role if needed
      await saveRole(role);

      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      _alert('Firebase Error', e.message ?? 'Unknown error');
    } catch (e) {
      _alert('Error', e.toString());
    }
  }

  Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _alert(String t, String m) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(t),
      content: Text(m),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  InputDecoration _dec(String lbl) => InputDecoration(
    labelText: lbl,
    labelStyle: const TextStyle(color: Colors.white70),
    border: const OutlineInputBorder(),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white54),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.tealAccent),
    ),
    suffixIcon: lbl == 'Password'
        ? IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.white70,
            ),
            onPressed: _togglePasswordVisibility,
          )
        : null,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/login_bg.jpg', fit: BoxFit.cover),
        ),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(.65))),
        LayoutBuilder(
          builder: (ctx, c) {
            final wide = c.maxWidth > 800;
            return wide
                ? Row(
                    children: [
                      _leftTagline(expanded: true),
                      Expanded(child: _form()),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _leftTagline(),
                      const SizedBox(height: 20),
                      _form(),
                    ],
                  );
          },
        ),
      ],
    ),
  );

  Widget _leftTagline({bool expanded = false}) =>
      expanded ? Expanded(child: _tagline()) : _tagline();

  Widget _tagline() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Welcome to ',
                style: TextStyle(fontSize: 38, color: Colors.white70),
              ),
              TextSpan(
                text: 'Eventra!',
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.bold,
                  color: Colors.tealAccent,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Text(
          '• Discover campus events\n• Connect & earn rewards',
          style: TextStyle(fontSize: 18, color: Colors.white54),
        ),
      ],
    ),
  );

  Widget _form() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Login to Eventra',
              style: TextStyle(fontSize: 26, color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailC,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passC,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Password'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _login,
              child: const Text('Login', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/signup'),
              child: const Text(
                "Don't have an account? Sign up",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
