import 'package:flutter/material.dart';
import 'dart:async';
import '../games/word_search.dart';
import 'quizzes.dart';
import '../games/game_start_screen_2048.dart';
import '../games/memory_match_start_screen.dart';
import 'daily.dart';
import 'leaderboard.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/presentation/app_drawer.dart';

class DailyContestPage extends StatefulWidget {
  const DailyContestPage({super.key});

  @override
  State<DailyContestPage> createState() => _DailyContestPageState();
}

class _DailyContestPageState extends State<DailyContestPage> {
  final GlobalKey leaderboardKey = GlobalKey();
  Duration _remainingTime = const Duration(hours: 23, minutes: 59, seconds: 59);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get formattedCountdown {
    return "${_remainingTime.inHours}:${(_remainingTime.inMinutes % 60).toString().padLeft(2, '0')}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  void _navigateToGame(String gameName) {
    Widget page;
    if (gameName == "Puzzles") {
      page = const DifficultySelectionPage();
    } else if (gameName == "Quizzes") {
      page = const QuizSelectionPage();
    } else if (gameName == "Funny Games") {
      page = const Game2048StartScreen();
    } else if (gameName == "Memory Match") {
      page = const MemoryMatchStartScreen();
    } else if (gameName == "Daily Contest") {
      page = const DailyContest();
    } else {
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Daily Contest'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Let's Play",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Text(
                "Explore today's fun picks!",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _mainHeroCard(),
              const SizedBox(height: 24),
              Text(
                "Quick Games",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _gamesHorizontalList(),
              const SizedBox(height: 32),
              DailyContestLeaderboardSection(key: leaderboardKey),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mainHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Daily Contest",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      formattedCountdown,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "One challenge a day keeps boredom away!",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _navigateToGame("Daily Contest"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Play Now'),
          ),
        ],
      ),
    );
  }

  Widget _gamesHorizontalList() {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _gameBox(
            "Puzzles",
            "Bend your brain!",
            Colors.orange,
            Icons.extension,
          ),
          _gameBox("Quizzes", "Think quick!", Colors.blue, Icons.quiz),
          _gameBox(
            "Funny Games",
            "Relax & Play",
            Colors.green,
            Icons.emoji_emotions,
          ),
          _gameBox("Memory Match", "Test focus", Colors.pink, Icons.psychology),
        ],
      ),
    );
  }

  Widget _gameBox(String title, String subtitle, Color color, IconData icon) {
    return GestureDetector(
      onTap: () => _navigateToGame(title),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
