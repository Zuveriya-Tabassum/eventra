import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game.dart'; // Import your Game2048 widget

class Game2048StartScreen extends StatefulWidget {
  const Game2048StartScreen({super.key});

  @override
  _Game2048StartScreenState createState() => _Game2048StartScreenState();
}

class _Game2048StartScreenState extends State<Game2048StartScreen> {
  int currentScore = 0;
  int bestScore = 0;
  DateTime? bestScoreTime;

  @override
  void initState() {
    super.initState();
    _loadScores();
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

  Future<void> _refreshBestScore() async {
    await _loadScores();
  }

  void _startGame() async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const Game2048()),
    );

    if (result != null) {
      setState(() {
        currentScore = result;
      });
      await _refreshBestScore();
    }
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
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Best Score and time
            Text(
              'Best Score: $bestScore',
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            // Current score
            Text(
              'Last Played Score: $currentScore',
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 40),

            // Centered Play Now button at bottom
            Center(
              child: SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Play Now',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
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
