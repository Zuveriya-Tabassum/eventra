import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameC = TextEditingController();
  final idC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final confirmC = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? role;

  final roles = ['Club Head', 'Participant'];
  final emailRx = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
  final passRx = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@#_]).{6,}$');

  final _auth = AuthService();

  // ---------- FIRESTORE HELPERS ----------

  Future<bool> _isStudentIdTaken(String sid) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('studentIdLower', isEqualTo: sid.toLowerCase())
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ---------- SIGNUP LOGIC ----------

  Future<void> _signup() async {
    final name = nameC.text.trim();
    final sid = idC.text.trim();
    final em = emailC.text.trim();
    final pw = passC.text.trim();
    final cf = confirmC.text.trim();

    if ([name, sid, em, pw, cf].any((e) => e.isEmpty)) {
      return _alert('Error', 'All fields are required.');
    }
    if (!emailRx.hasMatch(em)) {
      return _alert('Invalid Email', 'Only @gmail.com addresses are allowed.');
    }
    if (!passRx.hasMatch(pw)) {
      return _alert(
        'Weak Password',
        'Include a letter, number, and one of @  #  _. Minimum 6 characters.',
      );
    }
    if (pw != cf) {
      return _alert('Mismatch', 'Passwords do not match.');
    }
    if (role == null) {
      return _alert('Role Missing', 'Please choose a role.');
    }

    // 🔍 unique, case-insensitive roll / ID number
    if (await _isStudentIdTaken(sid)) {
      return _alert(
        'ID already registered',
        'This roll / ID number is already used (case-insensitive).\n'
            'Please enter a different roll number.',
      );
    }

    try {
      final user = await _auth.signUp(em, pw);
      if (user == null) {
        return _alert('Signup failed', 'Could not create account.');
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
        'studentId': sid,
        'studentIdLower': sid.toLowerCase(),
        'role': role,
        'status': 'pending', // New users are pending by default
        'email': em,
        'streak': 0,
        'lastVisitDate': null,
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      _alert(
        'Registration Successful',
        'Your account is pending admin approval. Please wait for the admin to approve your account before logging in.',
      );

      // Optionally sign out immediately so they don't stay logged in with a pending status
      await _auth.signOut();

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      _alert('Hi! there is an error :)', e.toString());
    }
  }

  // String _routeForRole(String r) => switch (r) {
  //   'Admin' => '/home',
  //   'Club Head' => '/home',
  //   'Participant' => '/home',
  //   _ => '/home',
  // };

  // ---------- UI HELPERS ----------

  void _togglePasswordVisibility(bool isConfirm) {
    setState(() {
      if (isConfirm) {
        _obscureConfirmPassword = !_obscureConfirmPassword;
      } else {
        _obscurePassword = !_obscurePassword;
      }
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

  // ---------- BUILD ----------

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (ctx, c) {
        final wide = c.maxWidth > 800;
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/login_bg.jpg', fit: BoxFit.cover),
            Container(color: Colors.black.withOpacity(.6)),
            wide
                ? Row(
                    children: [
                      Expanded(child: _tagline()),
                      Expanded(child: _form()),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [_tagline(), const SizedBox(height: 20), _form()],
                  ),
          ],
        );
      },
    ),
  );

  Widget _tagline() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Join ',
                style: TextStyle(fontSize: 42, color: Colors.white),
              ),
              TextSpan(
                text: 'Eventra',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.tealAccent,
                ),
              ),
              TextSpan(
                text: ' Today!',
                style: TextStyle(fontSize: 42, color: Colors.white),
              ),
            ],
          ),
        ),
        SizedBox(height: 40),
        Text(
          '• From Alerts to Achievements — Experience College Your Way.\n'
          '• Stay Updated. Stay Rewarded.',
          style: TextStyle(fontSize: 18, color: Colors.white70),
        ),
      ],
    ),
  );

  Widget _form() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Card(
        color: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Signup for Eventra',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameC,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: idC,
                decoration: InputDecoration(
                  labelText: 'ID Number',
                  prefixIcon: Icon(
                    Icons.badge_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailC,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passC,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () => _togglePasswordVisibility(false),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmC,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(
                    Icons.lock_reset,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () => _togglePasswordVisibility(true),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(
                    Icons.group_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                items: roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => role = v),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _signup,
                child: const Text('Sign Up', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: Text(
                  'Already have an account? Login',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
