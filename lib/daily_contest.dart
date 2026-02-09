import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'word_search.dart';
import 'quizzes.dart';
import 'gameStartScreen_2048.dart';
import 'memoryMatchStartScreen.dart';
import 'daily.dart';
import 'leaderboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    // Start live countdown (set to 24h for example)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<bool> _isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role') == 'admin';
  }

  String get formattedCountdown {
    return "${_remainingTime.inHours}:${(_remainingTime.inMinutes % 60)
        .toString()
        .padLeft(2, '0')}:${(_remainingTime.inSeconds % 60).toString().padLeft(
        2, '0')}";
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text("Daily Contest Rules"),
            content: const Text(
                "• Each user can participate once daily.\n"
                    "• Submit your solution before the timer ends!\n"
                    "• Top scorers earn badge and leaderboard points.\n"
                    "• Any misconduct leads to disqualification."
            ),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  void _navigateToGame(String gameName) {
    if (gameName == "Puzzles") {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const DifficultySelectionPage()),
      );
    } else if (gameName == "Quizzes") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EventraQuizApp()),
      );
    } else if (gameName == "Funny Games") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Game2048StartScreen()),
      );
    }
    else if (gameName == "Memory Match") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MemoryMatchStartScreen()),
      );
    } else if (gameName == "Daily Contest") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DailyContest()),
      );
    }
    else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                Scaffold(
                  appBar: AppBar(title: Text(gameName)),
                  body: Center(
                      child:
                      Text('Welcome to $gameName!',
                          style: const TextStyle(fontSize: 24))),
                )),
      );
    }
  }

  void _playNow() {
    _navigateToGame("Daily Contest");
  }

  @override
  Widget build(BuildContext context) {
    // return FutureBuilder<bool>(
    //   future: _isAdmin(),
    //   builder: (context, snapshot) {
    //     // 1️⃣ Loading
    //     if (!snapshot.hasData) {
    //       return const Scaffold(
    //         body: Center(child: CircularProgressIndicator()),
    //       );
    //     }
    //
    //     // 2️⃣ Not Admin → BLOCK
    //     if (!snapshot.data!) {
    //       return Scaffold(
    //         appBar: AppBar(
    //           title: const Text('Access Denied'),
    //           backgroundColor: Colors.red,
    //         ),
    //         body: const Center(
    //           child: Text(
    //             '❌ Admin Only Page',
    //             style: TextStyle(fontSize: 18, color: Colors.red),
    //           ),
    //         ),
    //       );
    //     }

        // 3️⃣ Admin UI
        final screenHeight = MediaQuery
            .of(context)
            .size
            .height;
        final screenWidth = MediaQuery
            .of(context)
            .size
            .width;

        return Scaffold(
          backgroundColor: const Color(0xFFE0F2F1),
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            title: const Text(
              'Daily Contest',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.teal,
            elevation: 0,
          ),

          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Let's Play",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004D40),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline, color: Color(
                            0xFF004D40)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) =>
                                AlertDialog(
                                  title: const Text("Eventra Info"),
                                  content: const Text(
                                      "Welcome to Eventra! Join contests and clubs."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Close"),
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  const Text(
                    "Explore today's fun picks!",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),

                  const SizedBox(height: 24),

                  Stack(
                    children: [
                      _StyledFloatingCard(
                        title: "Daily Contest",
                        quote: "One challenge a day keeps boredom away!",
                        imageUrl:
                        'https://cdn-icons-png.flaticon.com/512/4072/4072317.png',
                        gradientColors: const [
                          Color(0xFF00BCD4),
                          Color(0xFF004D40)
                        ],
                        height: screenHeight * 0.27,
                        width: screenWidth,
                        isHighlighted: true,
                        timerText: formattedCountdown,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _playNow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF004D40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('Play Now'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 200,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FixedSizeGameBox(
                          title: "Puzzles",
                          quote: "Bend your brain with daily puzzles!",
                          imageUrl:
                          'https://cdn-icons-png.flaticon.com/512/411/411776.png',
                          gradientColors: const [
                            Color(0xFFFF9A9E),
                            Color(0xFFFAD0C4)
                          ],
                          onTap: () => _navigateToGame("Puzzles"),
                        ),
                        const SizedBox(width: 16),
                        _FixedSizeGameBox(
                          title: "Quizzes",
                          quote: "Think quick, answer quicker!",
                          imageUrl:
                          'https://cdn-icons-png.flaticon.com/512/4257/4257483.png',
                          gradientColors: const [
                            Color(0xFFA18CD1),
                            Color(0xFFFBC2EB)
                          ],
                          onTap: () => _navigateToGame("Quizzes"),
                        ),
                        const SizedBox(width: 16),
                        _FixedSizeGameBox(
                          title: "Funny Games",
                          quote: "A giggle a day keeps stress away!",
                          imageUrl:
                          'https://cdn-icons-png.flaticon.com/512/4712/4712002.png',
                          gradientColors: const [
                            Color(0xFF84FAB0),
                            Color(0xFF8FD3F4)
                          ],
                          onTap: () => _navigateToGame("Funny Games"),
                        ),
                        const SizedBox(width: 16),
                        _FixedSizeGameBox(
                          title: "Memory Match",
                          quote: "Test your memory and focus!",
                          imageUrl:
                          'https://cdn-icons-png.flaticon.com/512/3448/3448449.png',
                          gradientColors: const [
                            Color(0xFFFFDEE9),
                            Color(0xFFB5FFFC)
                          ],
                          onTap: () => _navigateToGame("Memory Match"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  DailyContestLeaderboardSection(key: leaderboardKey),
                  const SizedBox(height: 30),


                ],
              ),
            ),
          ),

        );
      }
    // );
  }
// }
class _FixedSizeGameBox extends StatelessWidget {
  final String title;
  final String quote;
  final String imageUrl;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _FixedSizeGameBox({
    required this.title,
    required this.quote,
    required this.imageUrl,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 200,
            height: 210,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 36),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  quote,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -15,
            right: 16,
            child: Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Floating Card updated to support children ---

class _StyledFloatingCard extends StatelessWidget {
  final String title;
  final String quote;
  final String imageUrl;
  final List<Color> gradientColors;
  final double height;
  final double width;
  final bool isHighlighted;
  final Widget? child;
  final String? timerText;

  const _StyledFloatingCard({
    required this.title,
    required this.quote,
    required this.imageUrl,
    required this.gradientColors,
    required this.height,
    required this.width,
    this.isHighlighted = false,
    this.child,
    this.timerText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: height,
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(
                    isHighlighted ? 0.4 : 0.25),
                blurRadius: isHighlighted ? 12 : 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                quote,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (child != null) child!,
            ],
          ),
        ),
        if (timerText != null)
          Positioned(
            top: 36,
            right: 50,
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  timerText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        Positioned(
          top: -20,
          right: 16,
          child: SizedBox(
            height: 54,
            width: 54,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}
  class DailyContestHelper {
  static const _playedPrefix = 'played_';
  static const _enabledPrefix = 'enabled_';

  static Future<bool> isPlayedToday(String gameId) async {
  final prefs = await SharedPreferences.getInstance();
  final lastPlayed = prefs.getString('$_playedPrefix$gameId');
  if (lastPlayed == null) return false;

  final last = DateTime.parse(lastPlayed);
  final now = DateTime.now();

  return last.year == now.year &&
  last.month == now.month &&
  last.day == now.day;
  }

  static Future<void> markPlayed(String gameId) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString(
  '$_playedPrefix$gameId', DateTime.now().toIso8601String());
  }

  static Future<bool> isEnabled(String gameId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('$_enabledPrefix$gameId') ?? true;
  }

  static Future<void> setEnabled(String gameId, bool value) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setBool('$_enabledPrefix$gameId', value);
  }
  }


