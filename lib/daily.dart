import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quizzes.dart';

class DailyContest extends StatefulWidget {
  const DailyContest({super.key});

  @override
  State<DailyContest> createState() => _DailyContestState();
}

class _DailyContestState extends State<DailyContest> {
  final List<String> challenges = ['Logic', 'Number'];
  Map<String, bool> _participatedToday = {};
  Map<String, int> _todayScores = {};
  late String todayKey;
  late String playerId;
  late String playerName;
  bool _alreadyPlayed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    todayKey = "${today.year}-${today.month}-${today.day}";
    _loadUserAndInit();
  }

  Future<void> _loadUserAndInit() async {
    final prefs = await SharedPreferences.getInstance();

    playerId = prefs.getString('playerId') ?? 'guest';
    playerName = prefs.getString('playerName') ?? 'Player';

    final today = DateTime.now();
    todayKey = "${today.year}-${today.month}-${today.day}";

    await _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final prefs = await SharedPreferences.getInstance();

    _alreadyPlayed = prefs.getBool('$playerId-completed-$todayKey') ?? false;

    await _loadParticipation();
    await _loadScores();

    setState(() => _loading = false);
  }

  Future<void> _loadParticipation() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, bool> participation = {};

    for (var challenge in challenges) {
      bool played = prefs.getBool('$playerId-$challenge-$todayKey') ?? false;

      participation[challenge] = played;
    }

    setState(() => _participatedToday = participation);
  }

  Future<void> _loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, int> scores = {};

    for (var challenge in challenges) {
      int score = prefs.getInt('score-$playerId-$challenge-$todayKey') ?? 0;

      scores[challenge] = score;
    }

    setState(() => _todayScores = scores);
  }

  Future<void> _markParticipation(String challenge, int score) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('$playerId-$challenge-$todayKey', true);
    await prefs.setInt('score-$playerId-$challenge-$todayKey', score);

    setState(() {
      _participatedToday[challenge] = true;
      _todayScores[challenge] = score;
    });

    bool allPlayed = challenges.every((c) => _participatedToday[c] == true);

    if (allPlayed) {
      await prefs.setBool('$playerId-completed-$todayKey', true);
    }
  }

  void _tryStartChallenge(String challenge) async {
    if (_participatedToday[challenge] == true) {
      _showScoreDialogAutoClose(challenge, _todayScores[challenge] ?? 0);
      return;
    }

    // ⏱️ START TIMER

    final Map<String, dynamic>? result =
        await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (_) {
              switch (challenge) {
                case 'Logic':
                  return QuizPage(
                    title: 'Logic Quiz',
                    questions: QuizData.logicQuizShuffled(),
                  );
                case 'Number':
                  return QuizPage(
                    title: 'Number Quiz',
                    questions: QuizData.numberQuizShuffled(),
                  );
                default:
                  return const Scaffold(
                    body: Center(child: Text("Unknown challenge")),
                  );
              }
            },
          ),
        );

    if (result != null && result.containsKey('score')) {
      int score = result['score'] as int;

      // ⏱️ END TIMER

      await _markParticipation(challenge, score);

      _showScoreDialogAutoClose(challenge, score);
    }
  }

  void _showScoreDialogAutoClose(String challenge, int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.canPop(context)) Navigator.pop(context);
        });
        return AlertDialog(
          title: const Text('Challenge Completed'),
          content: Text('Your today\'s $challenge challenge score is: $score'),
        );
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    // 1️⃣ Loading state
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2️⃣ Already played → block screen
    if (_alreadyPlayed) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Daily Challenges"),
          backgroundColor: Colors.teal[300],
        ),
        body: const Center(
          child: Text(
            "❌ You have already completed today's contest",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 3️⃣ Normal contest UI
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Challenges"),
        backgroundColor: Colors.teal[300],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: challenges.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          final played = _participatedToday[challenge] ?? false;

          return ListTile(
            title: Text(
              challenge,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            trailing: played
                ? Text(
                    "Played: ${_todayScores[challenge] ?? 0} pts",
                    style: const TextStyle(color: Colors.grey),
                  )
                : ElevatedButton(
                    onPressed: () => _tryStartChallenge(challenge),
                    child: const Text("Play Now"),
                  ),
          );
        },
      ),
    );
  }
}
