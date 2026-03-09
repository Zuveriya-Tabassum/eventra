import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

import 'core/presentation/splash_screen.dart';
import 'core/presentation/onboarding_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/dashboard/home.dart';
import 'features/dashboard/admin_dashboard.dart';
import 'features/dashboard/clubhead_dashboard.dart';
import 'features/dashboard/participant_dashboard.dart';
import 'features/events/hackathon_list.dart';
import 'features/events/workshop_list.dart';
import 'features/contests/daily_contest.dart';
import 'features/clubs/club.dart';
import 'features/announcements/ann_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const EventraApp());
}

class EventraApp extends StatefulWidget {
  const EventraApp({super.key});

  @override
  State<EventraApp> createState() => _EventraAppState();
}

class _EventraAppState extends State<EventraApp> {
  final bool _isAdmin = false; // Keep your role logic placeholder

  @override
  Widget build(BuildContext context) {
    // Define a professional, modern Light Theme
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E88E5), // A professional deep blue/teal
      primary: const Color(0xFF1E88E5),
      secondary: const Color(0xFF00ACC1),
      surface: const Color(0xFFF8F9FA),
      background: const Color(0xFFF0F2F5),
      error: const Color(0xFFD32F2F),
      brightness: Brightness.light,
    );

    final TextTheme textTheme =
        GoogleFonts.interTextTheme(Theme.of(context).textTheme).copyWith(
          displayLarge: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          titleLarge: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          bodyLarge: GoogleFonts.inter(color: Colors.black87),
          bodyMedium: GoogleFonts.inter(color: Colors.black87),
        );

    return MaterialApp(
      title: 'Eventra',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.background,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
        ),
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
            return HomeScreen(isAdmin: _isAdmin);
          }

          // Not logged in
          return const LoginScreen();
        },
      ),

      // 🔥 KEEP ALL YOUR ROUTES (NOT REMOVED)
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/onboard': (_) => OnboardingScreen(goToHome: () => const EventraApp()),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),

        '/home': (_) => HomeScreen(isAdmin: _isAdmin),

        '/admin': (_) => const AdminDashboard(),

        '/clubhead': (_) => const ClubHeadDashboard(),
        '/participant': (_) => const ParticipantDashboard(),
        '/hackathon': (_) => const HackathonListPage(),
        '/workshops': (_) => const WorkshopListPage(),
        '/quizzes': (_) => const DailyContestPage(),
        '/clubhub': (_) => const ClubHubHomePage(),
        '/announcements': (_) => const AnnouncementPage(),
      },
    );
  }
}
