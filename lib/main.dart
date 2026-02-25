import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home.dart';
import 'screens/admin_dashboard.dart';
import 'screens/clubhead_dashboard.dart';
import 'screens/participant_dashboard.dart';
import 'screens/hackathon_list.dart';
import 'screens/workshop_list.dart';
import 'daily_contest.dart';
import 'screens/club.dart';
import 'screens/ann_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const EventraApp());
}

class EventraApp extends StatefulWidget {
  const EventraApp({super.key});

  @override
  State<EventraApp> createState() => _EventraAppState();
}

class _EventraAppState extends State<EventraApp> {
  ThemeMode _themeMode = ThemeMode.light;

  bool get _isDark => _themeMode == ThemeMode.dark;
  final bool _isAdmin = false; // Keep your role logic placeholder

  void _toggleTheme() {
    setState(() {
      _themeMode = _isDark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventra',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
        fontFamily: 'Poppins',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        fontFamily: 'Poppins',
      ),

      // 🔥 THIS FIXES HOT RESTART LOGIN ISSUE
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          // User already logged in
          if (snapshot.hasData) {
            return HomeScreen(
              onToggleTheme: _toggleTheme,
              isDark: _isDark,
              isAdmin: _isAdmin,
            );
          }

          // Not logged in
          return const LoginScreen();
        },
      ),

      // 🔥 KEEP ALL YOUR ROUTES (NOT REMOVED)
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/onboard': (_) =>
            OnboardingScreen(goToHome: () => const EventraApp()),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),

        '/home': (_) => HomeScreen(
              onToggleTheme: _toggleTheme,
              isDark: _isDark,
              isAdmin: _isAdmin,
            ),

        '/admin': (_) =>
            AdminDashboard(onToggleTheme: _toggleTheme, isDark: _isDark),

        '/clubhead': (_) => const ClubHeadDashboard(),
        '/participant': (_) => const ParticipantDashboard(),
        '/hackathon': (_) => const HackathonListPage(),
        '/workshops': (_) => const WorkshopListPage(),
        '/quizzes': (_) => const DailyContestPage(),
        '/clubhub': (_) => const ClubHubHomePage(),
        '/announcements': (_) =>
            AnnouncementPage(onToggleTheme: _toggleTheme),
      },
    );
  }
}