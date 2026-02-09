import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'daily_contest.dart';
import 'leaderboard.dart';
import 'dart:convert';

void main() {
  runApp(const MemoryGameApp());
}

enum Difficulty { easy, medium, hard }

class MemoryGameApp extends StatelessWidget {
  const MemoryGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const MemoryMatchStartScreen(),
    );
  }
}

/// -----------------
/// START SCREEN
/// -----------------
class MemoryMatchStartScreen extends StatefulWidget {
  const MemoryMatchStartScreen({super.key});

  @override
  State<MemoryMatchStartScreen> createState() =>
      _MemoryMatchStartScreenState();
}

class _MemoryMatchStartScreenState extends State<MemoryMatchStartScreen>
    with SingleTickerProviderStateMixin {
  String selectedLevel = 'easy';
  int currentScore = 0;
  int bestScore = 0;
  bool hasPlayed = false;

  late AnimationController _animController;
  late Animation<double> _animScore;

  @override
  void initState() {
    super.initState();
    _loadHasPlayed();
    _loadBestScore();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animScore = Tween<double>(begin: 0, end: currentScore.toDouble())
        .animate(CurvedAnimation(parent: _animController, curve: Curves.elasticOut));
  }
  Future<void> _loadHasPlayed() async {  // ✅ FIX DAILY
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hasPlayed = prefs.getBool('played-$_todayKey') ?? false;  // Daily key!
    });
  }
  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bestScore = prefs.getInt('matchPairBestScore') ?? 0;
    });
  }
  Future<void> _saveToLeaderboard(int score, SharedPreferences prefs) async {
    final todayKey = _todayKey;
    final playerId = prefs.getString('playerId') ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    final playerName = prefs.getString('playerName') ?? prefs.getString('displayName') ?? 'Player';

    List<String> ids = prefs.getStringList("daily_players_$todayKey") ?? [];
    if (!ids.contains(playerId)) ids.add(playerId);
    await prefs.setStringList("daily_players_$todayKey", ids);

    final raw = prefs.getString("player_${playerId}_$todayKey");
    Map<String, dynamic> playerData = raw != null
        ? jsonDecode(raw)
        : {"name": playerName, "totalTime": 0, "games": {}};

    playerData['games']['Memory Match'] = {
      "score": score,
      "best": (playerData['games']['Memory Match']?['best'] ?? 0) < score ? score : playerData['games']['Memory Match']?['best'] ?? 0,
      "played": true,
    };

    playerData['totalTime'] = (playerData['totalTime'] ?? 0) + 60;
    await prefs.setString("player_${playerId}_$todayKey", jsonEncode(playerData));

    LeaderboardStream().refresh();
  }

  Future<void> _updateBestScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    if (score > bestScore) {
      bestScore = score;
      await prefs.setInt('matchPairBestScore', score);
      setState(() {});
    }
  }

  void _startGame() async {
    if (hasPlayed) return;

    final prefs = await SharedPreferences.getInstance();
    final difficultyEnum = selectedLevel == 'easy' ? Difficulty.easy :
    selectedLevel == 'medium' ? Difficulty.medium : Difficulty.hard;

    final score = await Navigator.push<int>(  // Get score back!
      context,
      MaterialPageRoute(
        builder: (_) => MemoryMatchGame(difficulty: difficultyEnum),
      ),
    );

    if (score != null) {
      await prefs.setBool('played-$_todayKey', true);  // Daily lock
      await _saveToLeaderboard(score, prefs);          // ✅ LEADERBOARD MAGIC!

      await _updateBestScore(score);
      setState(() => hasPlayed = true);
    }
  }
  String get _todayKey {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }
  void _handleScoreUpdate(int score) async {
    setState(() {
      currentScore = score;
    });

    _animController.reset();
    _animScore = Tween<double>(begin: 0, end: currentScore.toDouble())
        .animate(CurvedAnimation(parent: _animController, curve: Curves.elasticOut));
    _animController.forward();

    if (score > bestScore) {
      await _updateBestScore(score);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('matchPairLastScore', score);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text('Memory Match Game'),
        centerTitle: true,
        backgroundColor: const Color(0xFF009688),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: hasPlayed ? null : _startGame,
        icon: const Icon(Icons.play_arrow),
        label: Text(hasPlayed ? "Already Played" : "Start the Fun"),
        backgroundColor: hasPlayed ? Colors.grey : const Color(0xFF80CBC4),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Want to check your memory power?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: Colors.teal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              const Text(
                "Select Difficulty",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              RadioListTile<String>(
                title: const Text('Easy'),
                value: 'easy',
                groupValue: selectedLevel,
                onChanged: (v) => setState(() => selectedLevel = v!),
              ),
              RadioListTile<String>(
                title: const Text('Medium'),
                value: 'medium',
                groupValue: selectedLevel,
                onChanged: (v) => setState(() => selectedLevel = v!),
              ),
              RadioListTile<String>(
                title: const Text('Hard'),
                value: 'hard',
                groupValue: selectedLevel,
                onChanged: (v) => setState(() => selectedLevel = v!),
              ),

              const SizedBox(height: 30),

              AnimatedBuilder(
                animation: _animController,
                builder: (_, __) {
                  return Text(
                    "Current Score: ${_animScore.value.toInt()}",
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                "Best Score: $bestScore",
                style: TextStyle(fontSize: 24, color: Colors.teal[300]),
              ),
              const SizedBox(height: 30),
              Icon(Icons.memory, size: 120, color: Colors.teal[200]),
            ],
          ),
        ),
      ),
    );
  }
}

/// -----------------
/// GAME SCREEN
/// -----------------
class MemoryMatchGame extends StatefulWidget {
  final Difficulty difficulty;
  final void Function(int)? onScoreUpdate;

  const MemoryMatchGame({super.key, required this.difficulty, this.onScoreUpdate});

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  late int gridCount;
  int score = 0;
  int secondsPassed = 0;
  Timer? _timer;
  late ConfettiController _confettiController;

  List<String> icons = [];
  List<bool> visible = [];
  List<bool> matched = [];
  int? firstIndex;
  int? secondIndex;
  bool lock = false;
  bool gameEnded = false;
  DateTime? _startTime;

  final List<String> emojiPool = [
    "😀","😎","🤩","🥳","😍","🤖","👻","🎃",
    "🐶","🐱","🦊","🐼","🐸","🐵","🦁","🐯",
    "🍎","🍌","🍓","🍉","🍍","🍒","🥝","🍑",
    "⚽","🏀","🏈","🎾","🎮","🎲","🚗","✈️",
    "🌈","⭐","🔥","⚡","💎","🎁","🎈","🎯",
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _setupGame();
    _startTime = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => secondsPassed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }


  // Exit button pressed
  void _onExitPressed() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Exit Game?"),
        content: const Text("Your current score will be counted as final."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // cancel
            child: const Text("Continue"),
          ),
          TextButton(
            onPressed: () {
              _timer?.cancel();
              Navigator.pop(context); // close confirmation
              Navigator.pop(context, score); // return score to start screen
            },
            child: const Text("Exit"),
          ),
        ],
      ),
    );
  }
  void _setupGame() {
    switch (widget.difficulty) {
      case Difficulty.easy:
        gridCount = 4;
        break;
      case Difficulty.medium:
        gridCount = 6;
        break;
      case Difficulty.hard:
        gridCount = 8;
        break;
    }

    final totalCards = gridCount * gridCount;
    final pairs = totalCards ~/ 2;

    icons = emojiPool.take(pairs).expand((e) => [e, e]).toList()..shuffle(Random());

    visible = List.filled(totalCards, false);
    matched = List.filled(totalCards, false);

    firstIndex = null;
    secondIndex = null;
    lock = false;
    gameEnded = false;
    secondsPassed = 0;
    _startTime = DateTime.now();
  }

  void _onCardTap(int index) {
    if (lock || visible[index] || matched[index] || gameEnded) return;

    setState(() => visible[index] = true);

    if (firstIndex == null) {
      firstIndex = index;
    } else {
      secondIndex = index;
      lock = true;

      Future.delayed(const Duration(milliseconds: 700), () {
        if (icons[firstIndex!] == icons[secondIndex!]) {
          matched[firstIndex!] = true;
          matched[secondIndex!] = true;
          _confettiController.play(); // celebration
        } else {
          visible[firstIndex!] = false;
          visible[secondIndex!] = false;
        }

        firstIndex = null;
        secondIndex = null;
        lock = false;
        setState(() {});
        widget.onScoreUpdate?.call(matched.where((e) => e).length);

        if (matched.every((m) => m)) {
          gameEnded = true;
          _showCompletionDialog();
        }
      });
    }
  }

  void _showCompletionDialog() async {
    final gameScore = matched.where((e) => e).length;
    final gameTime = secondsPassed;

    // 1️⃣ Show dialog and wait for user action
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("🎉 Game Completed!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Score: $gameScore"),
            Text("Time Taken: $gameTime seconds"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // 2️⃣ Save score first
              await onGameWon(gameScore, gameTime);

              // 3️⃣ Close dialog
              Navigator.pop(context);

              // 4️⃣ Exit game and return score to start screen
              if (mounted) Navigator.pop(context, gameScore);
            },
            child: const Text("Finish"),
          ),
        ],
      ),
    );
  }

  Future<void> showRulesDialog({
    required BuildContext context,
    required String gameTitle,
    required String rules,
    required VoidCallback onStart,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // force user to read/start
      builder: (_) => AlertDialog(
        title: Text("$gameTitle Rules"),
        content: Text(rules),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close the dialog
              onStart(); // start the game
            },
            child: const Text("Start"),
          ),
        ],
      ),
    );
  }


  void _exitGame() async {
    if (gameEnded) return;

    final exit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Exit Game?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Score so far: ${matched.where((m) => m).length}"),
            Text("Time taken: $secondsPassed seconds"),
            const SizedBox(height: 10),
            const Text(
              "Keep practicing to improve your memory!",
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.teal),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // continue playing
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // exit
            child: const Text("Exit"),
          ),
        ],
      ),
    );

    if (exit == true) {
      gameEnded = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasPlayed', true);
      _showExitDialog();
    }
  }
  Future<void> onGameWon(int score, int timeSeconds) async {
    final prefs = await SharedPreferences.getInstance();

    final todayKey =
        "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
    final playerId =
        prefs.getString('playerId') ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    final playerName =
        prefs.getString('playerName') ?? 'Player';

    List<String> ids = prefs.getStringList("daily_players_$todayKey") ?? [];
    if (!ids.contains(playerId)) ids.add(playerId);
    await prefs.setStringList("daily_players_$todayKey", ids);

    final raw = prefs.getString("player_${playerId}_$todayKey");
    Map<String, dynamic> playerData = raw != null
        ? jsonDecode(raw)
        : {"name": playerName, "totalTime": 0, "games": {}};

    playerData['games']['Memory Match'] = {
      "score": score,
      "best": (playerData['games']['Memory Match']?['best'] ?? 0) < score
          ? score
          : playerData['games']['Memory Match']?['best'] ?? 0,
      "played": true,
    };

    playerData['totalTime'] =
        (playerData['totalTime'] ?? 0) + timeSeconds;

    await prefs.setString(
        "player_${playerId}_$todayKey", jsonEncode(playerData));

    // 🔥 LIVE UPDATE
    LeaderboardStream().refresh();
  }


  void _showExitDialog() async {
    final gameScore = matched.where((e) => e).length;
    final gameTime = secondsPassed;

    // ✅ Save partial game too!
    onGameWon(gameScore, gameTime);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Game Ended"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Final Score: $gameScore"),
            Text("Time: $gameTime seconds"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text("View Leaderboard"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final squareSize = min(size.width, size.height * 0.8);
    final cardSize = squareSize / gridCount;

    return Scaffold(
      appBar: AppBar(
        title: Text("Level: ${widget.difficulty.name.toUpperCase()}"),
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: _onExitPressed,
        ),
        centerTitle: true,
      ),

      body: Stack(
        children: [
          Center(
            child: SizedBox(
              width: squareSize,
              height: squareSize,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: icons.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCount,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemBuilder: (_, index) {
                  return GestureDetector(
                    onTap: () => _onCardTap(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: matched[index]
                            ? Colors.green.shade300
                            : visible[index]
                            ? Colors.white
                            : Colors.blue.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          visible[index] || matched[index] ? icons[index] : "",
                          style: TextStyle(fontSize: cardSize * 0.5),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Timer display
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Time: $secondsPassed s",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange],
            ),
          ),
        ],
      ),
    );
  }
}
