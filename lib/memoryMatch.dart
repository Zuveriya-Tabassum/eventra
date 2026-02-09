import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

class MatchPairGame extends StatefulWidget {
  final void Function(int score)? onScoreUpdate;

  const MatchPairGame({Key? key, this.onScoreUpdate}) : super(key: key);

  @override
  _MatchPairGameState createState() => _MatchPairGameState();
}

class _MatchPairGameState extends State<MatchPairGame>
    with SingleTickerProviderStateMixin {
  // 10 pairs of emojis
  List<String> _icons = [
    "🍎","🍎",
    "🍌","🍌",
    "🍇","🍇",
    "🍓","🍓",
    "🍍","🍍",
    "🥝","🥝",
    "🍑","🍑",
    "🍒","🍒",
    "🥭","🥭",
    "🍉","🍉",
  ];

  List<bool> _visible = [];
  List<bool> _matched = [];
  int? _firstIndex;
  int? _secondIndex;
  int _matchesFound = 0;
  int _moves = 0;
  int _score = 0;
  Timer? _timer;
  int _seconds = 0;

  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      _icons.shuffle(Random());
      _visible = List.filled(_icons.length, false);
      _matched = List.filled(_icons.length, false);
      _firstIndex = null;
      _secondIndex = null;
      _matchesFound = 0;
      _moves = 0;
      _score = 0;
      _seconds = 0;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _seconds++;
        });
      });
    });
  }

  void _playSound(String asset) async {
    await _audioPlayer.play(AssetSource(asset));
  }

  void _onCardTapped(int index) {
    if (_visible[index] || _secondIndex != null || _matched[index]) return;

    setState(() {
      _visible[index] = true;
      if (_firstIndex == null) {
        _firstIndex = index;
      } else {
        _secondIndex = index;
        _moves++;
        if (_icons[_firstIndex!] == _icons[_secondIndex!]) {
          // Match found
          _matchesFound++;
          _score += 10;
          widget.onScoreUpdate?.call(_score);
          _matched[_firstIndex!] = true;
          _matched[_secondIndex!] = true;

          // Play match sound
          _playSound('sounds/match.mp3');

          // Confetti
          _confettiController.play();

          _firstIndex = null;
          _secondIndex = null;

          if (_matchesFound == _icons.length ~/ 2) {
            _timer?.cancel();

            // Win sound
            _playSound('sounds/win.mp3');

            // Full confetti
            _confettiController.play();

            // Game won dialog
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("You Won! 🎉"),
                content: Text(
                    "Score: $_score\nMoves: $_moves\nTime: ${_seconds}s"),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _startNewGame();
                      },
                      child: const Text("Restart"))
                ],
              ),
            );
          }
        } else {
          // Not a match, hide after delay
          Timer(const Duration(seconds: 1), () {
            setState(() {
              _visible[_firstIndex!] = false;
              _visible[_secondIndex!] = false;
              _firstIndex = null;
              _secondIndex = null;
            });
          });
        }
      }
    });
  }

  Widget _buildCard(int index) {
    bool isFlipped = _visible[index] || _matched[index];
    return GestureDetector(
      onTap: () => _onCardTapped(index),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) {
          final rotate = Tween(begin: pi, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (context, child) {
              final tilt = (animation.value - 0.5).abs() - 0.5;
              return Transform(
                transform: Matrix4.rotationY(rotate.value)
                  ..setEntry(3, 0, tilt * 0.003),
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        child: Container(
          key: ValueKey(isFlipped),
          decoration: BoxDecoration(
            color: isFlipped ? Colors.blue[200] : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
            boxShadow: isFlipped
                ? [
              BoxShadow(
                  color: Colors.blue.withOpacity(0.5),
                  blurRadius: 6,
                  offset: const Offset(2, 2))
            ]
                : [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 3,
                  offset: const Offset(2, 2))
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            isFlipped ? _icons[index] : "",
            style: const TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Match the Pair"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startNewGame,
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Score: $_score",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Moves: $_moves",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Time: ${_seconds}s",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5, // 10 pairs => 5x4 grid
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _icons.length,
                    itemBuilder: (context, index) {
                      return _buildCard(index);
                    },
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.red, Colors.blue, Colors.yellow, Colors.green],
            ),
          ),
        ],
      ),
    );
  }
}
