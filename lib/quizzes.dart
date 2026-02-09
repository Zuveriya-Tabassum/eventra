import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'daily_contest.dart';
import 'leaderboard.dart';
void main() {
  runApp(const EventraQuizApp());
}

class EventraQuizApp extends StatelessWidget {
  const EventraQuizApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Eventra Quiz Game',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 17, height: 1.5),
        ),
      ),
      home: const QuizSelectionPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class QuizSelectionPage extends StatefulWidget {
  const QuizSelectionPage({super.key});

  @override
  State<QuizSelectionPage> createState() => _QuizSelectionPageState();
}

class _QuizSelectionPageState extends State<QuizSelectionPage> {
  int bestScoreLogic = 0, currentScoreLogic = 0, timeLogic = 0;
  int bestScoreNumber = 0, currentScoreNumber = 0, timeNumber = 0;
  bool attemptedLogic = false, attemptedNumber = false;

  @override
  void initState() {
    super.initState();
    _loadQuizStats();
  }

  Future<void> _loadQuizStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bestScoreLogic = prefs.getInt('bestScoreLogic') ?? 0;
      currentScoreLogic = prefs.getInt('currentScoreLogic') ?? 0;
      timeLogic = prefs.getInt('timeLogic') ?? 0;
      bestScoreNumber = prefs.getInt('bestScoreNumber') ?? 0;
      currentScoreNumber = prefs.getInt('currentScoreNumber') ?? 0;
      timeNumber = prefs.getInt('timeNumber') ?? 0;

      attemptedLogic = prefs.getBool('attemptedLogic') ?? false;
      attemptedNumber = prefs.getBool('attemptedNumber') ?? false;
    });
  }

  Future<void> _updateQuizStats(String quizType, int score, int timeTaken) async {
    final prefs = await SharedPreferences.getInstance();
    if (quizType == 'logic') {
      setState(() {
        currentScoreLogic = score;
        timeLogic = timeTaken;
        if (score > bestScoreLogic) bestScoreLogic = score;
        attemptedLogic = true;
      });
      await prefs.setInt('currentScoreLogic', score);
      await prefs.setInt('timeLogic', timeTaken);
      await prefs.setInt('bestScoreLogic', bestScoreLogic);
      await prefs.setBool('attemptedLogic', true);
    } else if (quizType == 'number') {
      setState(() {
        currentScoreNumber = score;
        timeNumber = timeTaken;
        if (score > bestScoreNumber) bestScoreNumber = score;
        attemptedNumber = true;
      });
      await prefs.setInt('currentScoreNumber', score);
      await prefs.setInt('timeNumber', timeTaken);
      await prefs.setInt('bestScoreNumber', bestScoreNumber);
      await prefs.setBool('attemptedNumber', true);
    }
  }

  void _startQuiz(String quizType) async {
    if ((quizType == 'logic' && attemptedLogic) ||
        (quizType == 'number' && attemptedNumber)) {
      _showAlreadyAttemptedDialog();
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPage(
          title: quizType == 'logic' ? 'Logic Quiz' : 'Number Quiz',
          questions: quizType == 'logic'
              ? QuizData.logicQuizShuffled()
              : QuizData.numberQuizShuffled(),
        ),
      ),
    );

    if (result != null && result.containsKey('score') && result.containsKey('time')) {
      _updateQuizStats(quizType, result['score'], result['time']);
    }
  }

  void _showAlreadyAttemptedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Quiz Already Attempted"),
        content: const Text("You have already attempted this quiz.\nYou cannot reattempt."),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizSection({
    required String title,
    required int bestScore,
    required int currentScore,
    required int timeTaken,
    required VoidCallback onPlay,
    required bool attempted,
  }) {
    String formatTime(int seconds) {
      final Duration d = Duration(seconds: seconds);
      final String min = d.inMinutes.toString().padLeft(2, '0');
      final String sec = (d.inSeconds % 60).toString().padLeft(2, '0');
      return "$min:$sec";
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _scoreInfo('Current Score', currentScore.toString()),
                _scoreInfo('Best Score', bestScore.toString()),
                _scoreInfo('Time', timeTaken == 0 ? '--:--' : formatTime(timeTaken)),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: attempted ? Colors.grey : Colors.teal,
                ),
                onPressed: attempted ? null : onPlay,
                child: Text(
                  attempted ? "Already Attempted" : "Play Now",
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreInfo(String label, String value) {
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[300],
        title: const Text('Select a Quiz'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DailyContestPage()),
                  (route) => false,
            );
          },
        ),

      ),
      body: ListView(
        children: [
          _buildQuizSection(
            title: 'Logic Quiz',
            bestScore: bestScoreLogic,
            currentScore: currentScoreLogic,
            timeTaken: timeLogic,
            onPlay: () => _startQuiz('logic'),
            attempted: attemptedLogic,
          ),
          _buildQuizSection(
            title: 'Number Quiz',
            bestScore: bestScoreNumber,
            currentScore: currentScoreNumber,
            timeTaken: timeNumber,
            onPlay: () => _startQuiz('number'),
            attempted: attemptedNumber,
          ),
        ],
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> questions;

  const QuizPage({super.key, required this.title, required this.questions});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  int currentIndex = 0;
  List<Map<String, String>> answers = [];
  bool answered = false;
  bool _resultShown = false;
  late BuildContext _pageContext;


  AnimationController? _timerController;
  Timer? _countdownTimer;
  int remainingTime = 15;
  late Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()
      ..start();
    _startTimer();
  }

  void _startTimer() {
    remainingTime = 15;

    // 1. Safely dispose of existing timer/controller
    _countdownTimer?.cancel();
    _timerController?.dispose();

    // 2. Initialize the new controller
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: remainingTime),
    )
      ..addListener(() {
        setState(() {}); // Required to make the progress bar move
      });

    _timerController!.forward();

    // 3. Setup the countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() => remainingTime--);
      } else {
        _countdownTimer?.cancel();
      }
    });

    _timerController!.addStatusListener((status) {
      if (status == AnimationStatus.completed && !answered) {
        selectAnswer("No Answer");
      }
    });
  }

  void selectAnswer(String selected) {
    if (answered) return;
    setState(() => answered = true);

    final correct = widget.questions[currentIndex]["answer"] as String;
    answers.add({
      "question": widget.questions[currentIndex]["q"],
      "selected": selected,
      "correct": correct
    });

    _timerController?.stop();
    _countdownTimer?.cancel();

    // Auto-move to next question after short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (currentIndex == widget.questions.length - 1) {
        _finishQuiz();
      } else {
        setState(() {
          currentIndex++;
          answered = false;
        });
        _startTimer();
      }
    });
  }
  String get _todayKey {  // ✅ EXACTLY LIKE 2048
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  void _showResultDialog(int score, int time) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Quiz Summary"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Questions Attempted: ${answers.length}/${widget.questions
                    .length}",
              ),
              const SizedBox(height: 8),
              Text("Score: $score"),
              const SizedBox(height: 8),
              Text(
                score >= widget.questions.length * 0.8
                    ? "Excellent! 🎉"
                    : score >= widget.questions.length * 0.5
                    ? "Good Job! 👍"
                    : "Keep Practicing! 💪",
              ),
            ],
          ),
          actions: [

            /// ✅ REVIEW ANSWERS BUTTON
            ElevatedButton(
              onPressed: () {
                Navigator
                    .of(dialogContext, rootNavigator: true)
                    .pop(); // close summary
                _showAnswerReview(); // open review dialog
              },
              child: const Text("Review Correct Answers"),
            ),

            /// ✅ CLOSE BUTTON (works now)
            ElevatedButton(
              onPressed: () {
                int finalScore = answers
                    .where((a) => a['selected'] == a['correct'])
                    .length;
                int finalTime = _stopwatch.elapsed.inSeconds;

                // 1️⃣ Close Review Dialog
                Navigator.of(context, rootNavigator: true).pop();

                // 2️⃣ Close Quiz Page → returns to Selection Page
                Navigator.of(context).pop({
                  'score': finalScore,
                  'time': finalTime,
                });
              },
              child: const Text("Close"),
            ),

          ],
        );
      },
    );
  }
  void _exitQuiz() async {
    int finalScore =
        answers.where((a) => a['selected'] == a['correct']).length;
    int finalTime = _stopwatch.elapsed.inSeconds;

    // Save progress to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    if (widget.title.contains('Logic')) {
      if (finalScore > (prefs.getInt('bestScoreLogic') ?? 0)) {
        await prefs.setInt('bestScoreLogic', finalScore);
      }
      await prefs.setInt('currentScoreLogic', finalScore);
      await prefs.setInt('timeLogic', finalTime);
      await prefs.setBool('attemptedLogic', answers.isNotEmpty);
    } else {
      if (finalScore > (prefs.getInt('bestScoreNumber') ?? 0)) {
        await prefs.setInt('bestScoreNumber', finalScore);
      }
      await prefs.setInt('currentScoreNumber', finalScore);
      await prefs.setInt('timeNumber', finalTime);
      await prefs.setBool('attemptedNumber', answers.isNotEmpty);
    }

    // Show exit dialog with Review option
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Exit Quiz?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("You attempted ${answers.length}/${widget.questions.length} questions."),
              const SizedBox(height: 8),
              Text("Score: $finalScore"),
              const SizedBox(height: 8),
              Text("Time: ${_formatTime(finalTime)}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(); // Close dialog
              },
              child: const Text("Continue Quiz"),
            ),
            ElevatedButton(
              onPressed: () {
                // Close exit dialog
                Navigator.of(context, rootNavigator: true).pop();

                // Show review
                _showAnswerReview();
              },
              child: const Text("Review Answers"),
            ),
          ],
        );
      },
    );
  }

// Keep the _showAnswerReview as we updated before
  void _showAnswerReview() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (reviewContext) {
        return AlertDialog(
          title: const Text("Correct Answers Review"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: answers.length,
              itemBuilder: (context, index) {
                final item = answers[index];
                final bool isCorrect = item['selected'] == item['correct'];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Q${index + 1}: ${item['question']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Your Answer: ${item['selected']}",
                      style: TextStyle(
                        color: isCorrect ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Correct Answer: ${item['correct']}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                // Close review dialog and quiz page
                Navigator.of(reviewContext, rootNavigator: true).pop();

                int finalScore =
                    answers.where((a) => a['selected'] == a['correct']).length;
                int finalTime = _stopwatch.elapsed.inSeconds;

                Navigator.of(context).pop({
                  'score': finalScore,
                  'time': finalTime,
                });
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
// Helper to format time
  String _formatTime(int seconds) {
    final Duration d = Duration(seconds: seconds);
    final String min = d.inMinutes.toString().padLeft(2, '0');
    final String sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$min:$sec";
  }
  Future<void> _finishQuiz() async {
    if (_resultShown) return;
    _resultShown = true;

    _stopwatch.stop();
    _timerController?.stop();
    _countdownTimer?.cancel();

    int totalScore =
        answers.where((a) => a['selected'] == a['correct']).length;
    int totalTime = _stopwatch.elapsed.inSeconds;

    final prefs = await SharedPreferences.getInstance();

    // ✅ PLAYER INFO
    final playerId =
        prefs.getString('playerId') ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    final playerName =
        prefs.getString('playerName') ??
            prefs.getString('displayName') ??
            'Player';

    // ✅ SAVE TO DAILY LEADERBOARD
    await DailyContestLeaderboardSectionStateHelper.save(
      playerId: playerId,
      playerName: playerName,
      gameName: widget.title, // Logic Quiz / Number Quiz
      score: totalScore,
      timeSpentSeconds: totalTime,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showResultDialog(totalScore, totalTime);
    });
  }


  @override
  void dispose() {
    _timerController?.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var q = widget.questions[currentIndex];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.teal[300],
        title: Text(widget.title),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: "Exit Quiz",
            onPressed: _exitQuiz,
          ),

        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (child, animation) =>
            SlideTransition(
              position: Tween(
                  begin: const Offset(1, 0), end: const Offset(0, 0))
                  .animate(animation),
              child: child,
            ),
        child: Container(
          key: ValueKey<int>(currentIndex),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Question ${currentIndex + 1} of ${widget.questions.length}",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: 1 - (_timerController?.value ?? 0.0),
                  minHeight: 20,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(
                      (_timerController?.value ?? 0.0) > 0.66
                          ? Colors.red
                          : Colors.green
                  ),
                ),
              ), // <--- FIXED: Added ')' to close ClipRRect
              const SizedBox(height: 15),
              Text(q['q'],
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ...List.generate(q['options'].length, (i) {
                final opt = q['options'][i];
                Color color = Colors.white;

                if (answered) {
                  if (opt == q['answer']) {
                    color = Colors.green[300]!;
                  } else
                  if (answers.isNotEmpty && opt == answers.last['selected']) {
                    color = Colors.red[300]!;
                  }
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.black87,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: answered ? null : () => selectAnswer(opt),
                    child: Center(
                      child: Text(
                        opt,
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

}
/// ================= Quiz Data =================
class QuizData {
  static List<Map<String, dynamic>> logicQuestions = [
    {
      'q':
      "I speak without a mouth and hear without ears. I have no body, but I come alive with wind.",
      'options': ['Echo', 'Shadow', 'Wind', 'Fire'],
      'answer': 'Echo'
    },
    {
      'q': "The more of this there is, the less you see.",
      'options': ['Light', 'Fog', 'Darkness', 'Rain'],
      'answer': 'Darkness'
    },
    {
      'q': "What has keys but can't open locks?",
      'options': ['Piano', 'Map', 'Door', 'Computer'],
      'answer': 'Piano'
    },
    {
      'q': "What has hands but cannot clap?",
      'options': ['Clock', 'Robot', 'Chair', 'Statue'],
      'answer': 'Clock'
    },
    {
      'q':
      "I am always hungry and will die if not fed, but whatever I touch will soon turn red.",
      'options': ['Fire', 'Water', 'Plant', 'Earth'],
      'answer': 'Fire'
    },
  ];

  static List<Map<String, dynamic>> numberQuestions = [
    {'q': "Find the next number: 2, 4, 8, 16, ?", 'options': ['20', '32', '24', '18'], 'answer': '32'},
    {'q': "Find the missing number: 5, 10, 20, ?, 80", 'options': ['30', '40', '35', '50'], 'answer': '40'},
    {'q': "Find the next number: 1, 1, 2, 3, 5, ?", 'options': ['6', '7', '8', '9'], 'answer': '8'},
    {'q': "Find the missing number: 9, 7, 5, ?, 1", 'options': ['3', '2', '4', '0'], 'answer': '3'},
    {'q': "Find the next number: 10, 20, 40, 80, ?", 'options': ['100', '160', '120', '200'], 'answer': '160'},
  ];

  static List<Map<String, dynamic>> logicQuizShuffled() {
    var list = List<Map<String, dynamic>>.from(logicQuestions);
    list.shuffle(Random());
    return list;
  }

  static List<Map<String, dynamic>> numberQuizShuffled() {
    var list = List<Map<String, dynamic>>.from(numberQuestions);
    list.shuffle(Random());
    return list;
  }
}
