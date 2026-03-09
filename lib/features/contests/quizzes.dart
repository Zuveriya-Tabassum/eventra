import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'leaderboard.dart';
import 'package:google_fonts/google_fonts.dart';

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

  Future<void> _updateQuizStats(
    String quizType,
    int score,
    int timeTaken,
  ) async {
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

    if (result != null &&
        result.containsKey('score') &&
        result.containsKey('time')) {
      _updateQuizStats(quizType, result['score'], result['time']);
    }
  }

  void _showAlreadyAttemptedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Quiz Already Attempted"),
        content: const Text(
          "You have already attempted this quiz.\nYou cannot reattempt.",
        ),
        actions: [
          TextButton(
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
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _scoreInfo('Current', currentScore.toString()),
                _scoreInfo('Best', bestScore.toString()),
                _scoreInfo(
                  'Time',
                  timeTaken == 0 ? '--:--' : formatTime(timeTaken),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: attempted ? Colors.grey.shade300 : Theme.of(context).colorScheme.primary,
                  foregroundColor: attempted ? Colors.grey : Colors.white,
                ),
                onPressed: attempted ? null : onPlay,
                child: Text(
                  attempted ? "Already Attempted" : "Play Now",
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Select a Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
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

  AnimationController? _timerController;
  Timer? _countdownTimer;
  int remainingTime = 15;
  late Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _startTimer();
  }

  void _startTimer() {
    remainingTime = 15;
    _countdownTimer?.cancel();
    _timerController?.dispose();

    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: remainingTime),
    )..addListener(() {
      setState(() {});
    });

    _timerController!.forward();

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
      "correct": correct,
    });

    _timerController?.stop();
    _countdownTimer?.cancel();

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
              Text("Questions Attempted: ${answers.length}/${widget.questions.length}"),
              const SizedBox(height: 8),
              Text("Score: $score", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showAnswerReview();
              },
              child: const Text("Review Answers"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(); // Close all dialogs
                Navigator.of(context).pop({'score': score, 'time': time});
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _exitQuiz() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Exit Quiz?"),
        content: const Text("Are you sure you want to exit? Your progress will not be saved."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text("Exit")),
        ],
      ),
    );
  }

  void _showAnswerReview() {
    showDialog(
      context: context,
      builder: (reviewContext) {
        return AlertDialog(
          title: const Text("Review"),
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
                    Text("Q${index + 1}: ${item['question']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Your Answer: ${item['selected']}", style: TextStyle(color: isCorrect ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
                    Text("Correct Answer: ${item['correct']}", style: const TextStyle(color: Colors.green)),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(onPressed: () => Navigator.pop(reviewContext), child: const Text("Close")),
          ],
        );
      },
    );
  }

  Future<void> _finishQuiz() async {
    if (_resultShown) return;
    _resultShown = true;
    _stopwatch.stop();
    _timerController?.stop();
    _countdownTimer?.cancel();

    int totalScore = answers.where((a) => a['selected'] == a['correct']).length;
    int totalTime = _stopwatch.elapsed.inSeconds;

    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString('uid') ?? 'guest';
    final playerName = prefs.getString('name') ?? 'Player';

    await DailyContestLeaderboardSectionStateHelper.save(
      playerId: playerId,
      playerName: playerName,
      gameName: widget.title,
      score: totalScore,
      timeSpentSeconds: totalTime,
    );

    _showResultDialog(totalScore, totalTime);
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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(widget.title),
        automaticallyImplyLeading: false,
        actions: [IconButton(icon: const Icon(Icons.close), onPressed: _exitQuiz)],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: 1 - (_timerController?.value ?? 0.0),
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Question ${currentIndex + 1} of ${widget.questions.length}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text(q['q'], style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  ...List.generate(q['options'].length, (i) {
                    final opt = q['options'][i];
                    Color color = Colors.white;
                    if (answered) {
                      if (opt == q['answer']) color = Colors.green.shade100;
                      else if (answers.isNotEmpty && opt == answers.last['selected']) color = Colors.red.shade100;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.black87,
                          minimumSize: const Size(double.infinity, 56),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        onPressed: answered ? null : () => selectAnswer(opt),
                        child: Text(opt, style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuizData {
  static List<Map<String, dynamic>> logicQuestions = [
    {'q': "I speak without a mouth and hear without ears. I have no body, but I come alive with wind.", 'options': ['Echo', 'Shadow', 'Wind', 'Fire'], 'answer': 'Echo'},
    {'q': "The more of this there is, the less you see.", 'options': ['Light', 'Fog', 'Darkness', 'Rain'], 'answer': 'Darkness'},
    {'q': "What has keys but can't open locks?", 'options': ['Piano', 'Map', 'Door', 'Computer'], 'answer': 'Piano'},
    {'q': "What has hands but cannot clap?", 'options': ['Clock', 'Robot', 'Chair', 'Statue'], 'answer': 'Clock'},
    {'q': "I am always hungry and will die if not fed, but whatever I touch will soon turn red.", 'options': ['Fire', 'Water', 'Plant', 'Earth'], 'answer': 'Fire'},
  ];
  static List<Map<String, dynamic>> numberQuestions = [
    {'q': "Find the next number: 2, 4, 8, 16, ?", 'options': ['20', '32', '24', '18'], 'answer': '32'},
    {'q': "Find the missing number: 5, 10, 20, ?, 80", 'options': ['30', '40', '35', '50'], 'answer': '40'},
    {'q': "Find the next number: 1, 1, 2, 3, 5, ?", 'options': ['6', '7', '8', '9'], 'answer': '8'},
    {'q': "Find the missing number: 9, 7, 5, ?, 1", 'options': ['3', '2', '4', '0'], 'answer': '3'},
    {'q': "Find the next number: 10, 20, 40, 80, ?", 'options': ['100', '160', '120', '200'], 'answer': '160'},
  ];
  static List<Map<String, dynamic>> logicQuizShuffled() { var list = List<Map<String, dynamic>>.from(logicQuestions); list.shuffle(Random()); return list; }
  static List<Map<String, dynamic>> numberQuizShuffled() { var list = List<Map<String, dynamic>>.from(numberQuestions); list.shuffle(Random()); return list; }
}
