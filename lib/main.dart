import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

/* ─── Existing screens ─── */
import 'screens/club.dart';
import 'screens/admin_dashboard.dart';
import 'screens/clubdetail.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/clubhead_dashboard.dart';
import 'screens/participant_dashboard.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home.dart';
import 'screens/hackathon_list.dart';
import 'screens/workshop_list.dart';
import 'daily_contest.dart';

/* ─── Announcements module ─── */
import 'screens/ann_page.dart';
import 'screens/ann_models.dart';

/// ----------------- SAMPLE ANNOUNCEMENTS -----------------
final List<Announcement> sampleAnnouncements = [
  Announcement(
    id: 'a1',
    title: "Workshop on Flutter",
    description:
    "Join us for an interactive Flutter workshop. Learn to build beautiful apps!",
    venue: "Room 101, CS Block",
    date: DateTime(2026, 1, 10),
    time: const TimeOfDay(hour: 10, minute: 30),
    category: AnnouncementCategory.notice,
    isImportant: true,
  ),
  Announcement(
    id: 'a2',
    title: "Annual Sports Meet",
    description:
    "Participate in our annual sports events. Register before the 5th of January.",
    venue: "College Sports Ground",
    date: DateTime(2026, 1, 15),
    time: const TimeOfDay(hour: 8, minute: 0),
    category: AnnouncementCategory.event,
    isImportant: false,
  ),
  Announcement(
    id: 'a3',
    title: "Guest Lecture: AI Trends",
    description:
    "A lecture on the latest trends in AI by industry expert Dr. Kumar.",
    venue: "Auditorium",
    date: DateTime(2026, 1, 20),
    time: const TimeOfDay(hour: 14, minute: 0),
    category: AnnouncementCategory.notice,
    isImportant: true,
  ),
  Announcement(
    id: 'a4',
    title: "Cultural Fest 2026",
    description:
    "Get ready for our annual cultural fest. Music, dance, drama, and more!",
    venue: "Main Hall",
    date: DateTime(2026, 2, 5),
    time: const TimeOfDay(hour: 16, minute: 0),
    category: AnnouncementCategory.event,
    isImportant: false,
  ),
];

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
  ThemeMode _mode = ThemeMode.light;

  // TODO: replace with value loaded from Firestore after login.
  // For now this is just a placeholder you can change during testing.
  String _userRole = 'Participant'; // 'Admin', 'Club Head', 'Participant', ...

  void _toggleTheme() {
    setState(() {
      _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Widget _buildHome() => HomeScreen(
    onToggleTheme: _toggleTheme,
    isDark: _mode == ThemeMode.dark,
    isAdmin: _userRole == 'Admin' || _userRole == 'Club Head',
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventra',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/onboard': (_) => OnboardingScreen(goToHome: _buildHome),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => _buildHome(),
        '/home1': (_) => HomeScreen(
          onToggleTheme: _toggleTheme,
          isDark: _mode == ThemeMode.dark,
          isAdmin: _userRole == 'Admin' || _userRole == 'Club Head',
        ),

        '/admin': (_) => AdminDashboard(
          onToggleTheme: _toggleTheme,
          isDark: _mode == ThemeMode.dark,
        ),
        '/clubhead': (_) => const ClubHeadDashboard(),
        '/participant': (_) => const ParticipantDashboard(),
        '/hackathon': (_) => const HackathonListPage(),

        // club related
        '/clubhub': (_) => const ClubHubHomePage(),
        // '/clubdetail': (_) => ClubDetailsPage(...); // if needed

        '/workshops': (_) => const WorkshopListPage(),
        '/quizzes': (_) => const DailyContestPage(),

        /// ─── Announcements screen ───
        '/announcements': (_) => AnnouncementPage(
          onToggleTheme: _toggleTheme,
          // announcements: sampleAnnouncements,

        ),
      },
    );
  }
}
