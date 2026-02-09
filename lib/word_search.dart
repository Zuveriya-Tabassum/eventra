import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:find_the_word/find_the_word.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'word_bank.dart';
import 'dart:convert';
import 'leaderboard.dart';

enum Difficulty { easy, medium, hard }

/* ───────── WORD + TIME CONFIG ───────── */

List<String> getRandomWords(Difficulty difficulty) {
  final rand = Random();
  List<String> filtered;

  if (difficulty == Difficulty.easy) {
    filtered = wordBank.where((w) => w.length <= 5).toList();
    return (filtered..shuffle(rand)).take(5).toList();
  } else if (difficulty == Difficulty.medium) {
    filtered = wordBank.where((w) => w.length > 5 && w.length <= 10).toList();
    return (filtered..shuffle(rand)).take(9).toList();
  } else {
    filtered = wordBank.where((w) => w.length > 10).toList();
    return (filtered..shuffle(rand)).take(12).toList();
  }
}

int getTimeForDifficulty(Difficulty difficulty) => 120;

/* ───────── ATTEMPT & SCORE HELPERS ───────── */
Future<void> saveWordSearchToLeaderboard({
  required int score,
  required int timeSpentSeconds,
}) async {
  final prefs = await SharedPreferences.getInstance();

  final playerId =
      prefs.getString('playerId') ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
  final playerName =
      prefs.getString('playerName') ??
          prefs.getString('displayName') ??
          'Player';

  // 1️⃣ Register player for today
  List<String> ids = prefs.getStringList("daily_players_$todayKey") ?? [];
  if (!ids.contains(playerId)) ids.add(playerId);
  await prefs.setStringList("daily_players_$todayKey", ids);

  // 2️⃣ Load / create player data
  final raw = prefs.getString("player_${playerId}_$todayKey");
  Map<String, dynamic> playerData = raw != null
      ? jsonDecode(raw)
      : {"name": playerName, "totalTime": 0, "games": {}};

  // 3️⃣ Save game result
  playerData['games']['Word Search'] = {
    "score": score,
    "best": (playerData['games']['Word Search']?['best'] ?? 0) < score
        ? score
        : playerData['games']['Word Search']?['best'] ?? 0,
    "played": true,
  };

  playerData['totalTime'] =
      (playerData['totalTime'] ?? 0) + timeSpentSeconds;

  await prefs.setString(
      "player_${playerId}_$todayKey", jsonEncode(playerData));

  // 4️⃣ Lock attempt for today
  await prefs.setBool(
      'word_search_${Difficulty.easy.name}_played_$todayKey', true);
  await prefs.setBool(
      'word_search_${Difficulty.medium.name}_played_$todayKey', true);
  await prefs.setBool(
      'word_search_${Difficulty.hard.name}_played_$todayKey', true);

  // 🔥 Live refresh
  LeaderboardStream().refresh();
}
String get todayKey {
  final d = DateTime.now();
  return "${d.year}-${d.month}-${d.day}";
}

Future<bool> hasPlayed(Difficulty diff) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('word_search_${diff.name}_played') ?? false;
}

Future<void> saveScoreOnce(Difficulty diff, int score) async {
  final prefs = await SharedPreferences.getInstance();
  final playedKey = 'word_search_${diff.name}_played';

  if (prefs.getBool(playedKey) == true) return;

  await prefs.setBool(playedKey, true);
  await prefs.setInt('word_search_${diff.name}_score', score);

  final total = prefs.getInt('total_score') ?? 0;
  await prefs.setInt('total_score', total + score);
}

/* ───────── MAIN ENTRY ───────── */

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DifficultySelectionPage(),
  ));
}

/* ───────── DIFFICULTY SELECTION ───────── */

class DifficultySelectionPage extends StatefulWidget {
  const DifficultySelectionPage({super.key});

  @override
  State<DifficultySelectionPage> createState() =>
      _DifficultySelectionPageState();
}

class _DifficultySelectionPageState extends State<DifficultySelectionPage> {
  Map<Difficulty, int> bestScores = {
    Difficulty.easy: 0,
    Difficulty.medium: 0,
    Difficulty.hard: 0,
  };

  Map<Difficulty, int> lastScores = {
    Difficulty.easy: 0,
    Difficulty.medium: 0,
    Difficulty.hard: 0,
  };
  Future<void> _playWordSearch(Difficulty diff) async {
    // 🔒 Daily lock
    if (!await DailyPlayLock.canPlayWordSearch()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Already played today ❌")),
      );
      return;
    }

    // ▶️ Start game
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordSearchGameScreen(
          difficulty: diff,
          onFinished: (score) async {
            await saveScoreOnce(diff, score);
            await _updateScores(diff, score);
            await DailyPlayLock.markWordSearchPlayed();
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var d in Difficulty.values) {
        bestScores[d] = prefs.getInt('bestScore_${d.name}') ?? 0;
        lastScores[d] = prefs.getInt('lastScore_${d.name}') ?? 0;
      }
    });
  }

  Future<void> _updateScores(Difficulty diff, int score) async {
    final prefs = await SharedPreferences.getInstance();
    lastScores[diff] = score;

    if (score > bestScores[diff]!) {
      bestScores[diff] = score;
    }

    await prefs.setInt('lastScore_${diff.name}', score);
    await prefs.setInt('bestScore_${diff.name}', bestScores[diff]!);

    setState(() {});
  }

  Widget difficultyButton(
      Difficulty diff, String label, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 18)),
      onPressed: () async {
    final played = await hasPlayed(diff);

    if (played) {
    showDialog(
    context: context,
    builder: (_) => const AlertDialog(
    title: Text("Attempt Used"),
    content: Text("You already attempted this difficulty."),
    ),
    );
    return;
    }
    await showRulesDialog(
    context: context,
    title: "Word Search Rules",
    rules: "Find all the words hidden in the grid. You have 120 seconds. "
    "The words will be in any shape not only |,__,/.There may be multiple shapes like L,..  ""Each word gives 10 points. Bonus 50 points for finding all words!",
    onStart:(){
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (_) => WordSearchGameScreen(
    difficulty: diff,
    onFinished: (score) async {
    await saveScoreOnce(diff, score);
    await _updateScores(diff, score);
    },
    ),
    ),
    );
    },
    );
    },
    );
  }
        Future<void> showRulesDialog({
    required BuildContext context,
    required String title,
    required String rules,
    VoidCallback? onStart,
    }) async {
      return showDialog(
        context: context,
        barrierDismissible: false, // forces user to read/start
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(rules),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close the dialog
                if (onStart != null) onStart(); // start the game
              },
              child: const Text("Start"),
            ),
          ],
        ),
      );
    }

    Widget scoreRow(String title, int best, int last) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("Best: $best"),
              Text("Last: $last",
                  style: const TextStyle(color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Difficulty")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                difficultyButton(Difficulty.easy, "Easy", Colors.teal),
                difficultyButton(
                    Difficulty.medium, "Medium", Colors.purple),
                difficultyButton(
                    Difficulty.hard, "Hard", Colors.redAccent),
              ],
            ),
            const SizedBox(height: 30),
            scoreRow("Easy", bestScores[Difficulty.easy]!,
                lastScores[Difficulty.easy]!),
            scoreRow("Medium", bestScores[Difficulty.medium]!,
                lastScores[Difficulty.medium]!),
            scoreRow("Hard", bestScores[Difficulty.hard]!,
                lastScores[Difficulty.hard]!),
          ],
        ),
      ),
    );
  }
}

/* ───────── GAME SCREEN ───────── */

class WordSearchGameScreen extends StatefulWidget {
  final Difficulty difficulty;
  final Function(int) onFinished;

  const WordSearchGameScreen({
    super.key,
    required this.difficulty,
    required this.onFinished,
  });

  @override
  State<WordSearchGameScreen> createState() =>
      _WordSearchGameScreenState();
}
class DailyPlayLock {
  static Future<bool> canPlayWordSearch() async {
    final prefs = await SharedPreferences.getInstance();
    final key = DailyContestLeaderboardSectionStateHelper.todayKey;
    return !(prefs.getBool("played_word_search_$key") ?? false);
  }

  static Future<void> markWordSearchPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final key = DailyContestLeaderboardSectionStateHelper.todayKey;
    await prefs.setBool("played_word_search_$key", true);
  }
}

class _WordSearchGameScreenState extends State<WordSearchGameScreen> {
  late WordSearchGame _game;
  late List<String> _words; // store target words
  int foundCount = 0;
  int score = 0;

  bool _submitted = false;
  late Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _words = getRandomWords(widget.difficulty);

    _game = WordSearchGame(
      config: WordSearchConfig(
        words: _words,
        timeLimit: getTimeForDifficulty(widget.difficulty).toDouble(),
        primaryColor: Colors.teal,
        secondaryColor: Colors.purple,

        onGameOver: (result) {
          foundCount = result.foundWords.length;
          score = _calculateScore();
          _submitScoreAndExit(score, showDialogBox: true);

        },
      ),
    );
  }

  int _calculateScore() {
    int s = foundCount * 10;
    if (foundCount == _words.length) s += 50; // bonus for finding all
    return s;
  }
  Future<void> _submitScoreAndExit(
      int finalScore, {
        bool showDialogBox = false,
      }) async {
    if (_submitted) return;
    _submitted = true;
    _stopwatch.stop();
    await saveWordSearchToLeaderboard(
      score: finalScore,
      timeSpentSeconds: _stopwatch.elapsed.inSeconds,
    );
    await DailyPlayLock.markWordSearchPlayed();
    widget.onFinished(finalScore);

    if (showDialogBox) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Game Over 🎉"),
          content: Text(
            "Words Found: $foundCount / ${_words.length}\nScore: $finalScore",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text("Exit"),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> showRulesDialog({
    required BuildContext context,
    required String title,
    required String rules,
    VoidCallback? onStart,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // force user to read/start
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(rules),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close the dialog
              if (onStart != null) onStart(); // start the game
            },
            child: const Text("Start"),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    final currentFound = _game.foundWords.length;
    foundCount = currentFound;
    final currentScore = _calculateScore();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Exit Game? 🤔"),
        content: Text(
          "Words Found: $foundCount / ${_words.length}\n"
              "Score if you exit now: $currentScore",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Continue"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _submitScoreAndExit(currentScore);
            },

            child: const Text("Exit"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Word Search - ${widget.difficulty.name.toUpperCase()}"),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: "Exit Game",
              onPressed: _showExitConfirmation,
            ),
          ],
        ),
        body: Center(
          child: GameWidget(game: _game),
        ),
      ),
    );
  }
}
