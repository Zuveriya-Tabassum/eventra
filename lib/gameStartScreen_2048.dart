import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_2048.dart';
import 'leaderboard.dart';  // For LeaderboardStream
import 'dart:convert';

class Game2048StartScreen extends StatefulWidget {
  const Game2048StartScreen({super.key});

  @override
  State<Game2048StartScreen> createState() => _Game2048StartScreenState();
}
class _Game2048StartScreenState extends State<Game2048StartScreen> {
  int currentScore = 0;
  int bestScore = 0;
  DateTime? bestScoreTime;
  bool alreadyPlayed = false;

  @override
  void initState() {
    super.initState();
    _loadScores();
    _checkPlayedStatus();
  }

  String get _todayKey {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  Future<void> _checkPlayedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      alreadyPlayed = prefs.getBool('played-$_todayKey') ?? false;
    });
  }

  Future<void> _loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bestScore = prefs.getInt('bestScore2048') ?? 0;
      final timestamp = prefs.getInt('bestScoreTime2048');
      if (timestamp != null) {
        bestScoreTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    });
  }

  Future<void> _startGame() async {
    final prefs = await SharedPreferences.getInstance();

    final score = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const Game2048()),
    );

    if (score != null) {
      await prefs.setBool('played-$_todayKey', true);

      // ✅ 2048 LEADERBOARD INTEGRATION (3 LINES):
      await _saveToLeaderboard(score, prefs);

      setState(() {
        currentScore = score;
        alreadyPlayed = true;
      });
      await _loadScores();
    }
  }

  Future<void> _saveToLeaderboard(int score, SharedPreferences prefs) async {
    final todayKey = _todayKey;
    final playerId = prefs.getString('playerId') ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    final playerName = prefs.getString('playerName') ?? 'player';

    // EXACT SAME FORMAT as Memory Match:
    List<String> ids = prefs.getStringList("daily_players_$todayKey") ?? [];
    if (!ids.contains(playerId)) ids.add(playerId);
    await prefs.setStringList("daily_players_$todayKey", ids);

    final raw = prefs.getString("player_${playerId}_$todayKey");
    Map<String, dynamic> playerData = raw != null
        ? jsonDecode(raw)
        : {"name": playerName, "totalTime": 0, "games": {}};

    playerData['games']['2048'] = {
      "score": score,
      "best": (playerData['games']['2048']?['best'] ?? 0) < score ? score : playerData['games']['2048']?['best'] ?? 0,
      "played": true,
    };

    playerData['totalTime'] = (playerData['totalTime'] ?? 0) + 60; // Assume 1 min playtime
    await prefs.setString("player_${playerId}_$todayKey", jsonEncode(playerData));

    LeaderboardStream().refresh(); // INSTANT UPDATE!
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2048 Game'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Remarks',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Best Score: $bestScore',
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 12),

            Text(
              'Last Played Score: $currentScore',
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 30),

            Center(
              child: SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: alreadyPlayed ? null : _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    alreadyPlayed ? Colors.grey : Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    alreadyPlayed ? "Already Played" : "Play Now",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            if (alreadyPlayed)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(
                    "Come back tomorrow!",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
