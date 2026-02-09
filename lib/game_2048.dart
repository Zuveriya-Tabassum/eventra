import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

class Game2048 extends StatefulWidget {
  const Game2048({super.key});

  @override
  _Game2048State createState() => _Game2048State();
}

class _Game2048State extends State<Game2048> {
  static const int gridCount = 4;
  late List<List<int>> grid=List.generate(4, (_) => List.filled(4, 0));
  int score = 0;
  bool gameOver = false;
  bool playedToday = false;
  bool alreadyPlayed = false;

  final String todayKey =
      "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";

  @override
  void initState() {
    super.initState();
    _checkPlayedStatus();
    _addRandomTile();
    _addRandomTile();
  }

  Future<void> _checkPlayedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey =
        "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";

    setState(() {
      alreadyPlayed = prefs.getBool('played-$todayKey') ?? false;
    });
  }

  void _addRandomTile() {
    List<Point<int>> empty = [];
    for (int r = 0; r < gridCount; r++) {
      for (int c = 0; c < gridCount; c++) {
        if (grid[r][c] == 0) empty.add(Point(r, c));
      }
    }
    if (empty.isNotEmpty) {
      final cell = empty[Random().nextInt(empty.length)];
      grid[cell.x][cell.y] = Random().nextInt(10) == 0 ? 4 : 2;
    }
  }

  bool _canMove() {
    for (int r = 0; r < gridCount; r++) {
      for (int c = 0; c < gridCount; c++) {
        if (grid[r][c] == 0) return true;
        if (r < gridCount - 1 && grid[r][c] == grid[r + 1][c]) return true;
        if (c < gridCount - 1 && grid[r][c] == grid[r][c + 1]) return true;
      }
    }
    return false;
  }

  void _moveLeft() {
    setState(() {
      bool moved = false;
      for (int r = 0; r < gridCount; r++) {
        List<int> line = grid[r].where((v) => v != 0).toList();
        for (int i = 0; i < line.length - 1; i++) {
          if (line[i] == line[i + 1]) {
            line[i] *= 2;
            score += line[i];
            line[i + 1] = 0;
          }
        }
        line = line.where((v) => v != 0).toList();
        while (line.length < gridCount) line.add(0);
        if (!listEquals(grid[r], line)) moved = true;
        grid[r] = line;
      }
      if (moved) _addRandomTile();
    });
    _checkGameOver();
  }

  void _moveRight() {
    _reverseGrid();
    _moveLeft();
    _reverseGrid();
  }

  void _moveUp() {
    _transposeGrid();
    _moveLeft();
    _transposeGrid();
  }

  void _moveDown() {
    _transposeGrid();
    _moveRight();
    _transposeGrid();
  }

  void _reverseGrid() {
    for (int i = 0; i < gridCount; i++) {
      grid[i] = grid[i].reversed.toList();
    }
  }

  void _transposeGrid() {
    List<List<int>> newGrid =
    List.generate(gridCount, (_) => List.filled(gridCount, 0));
    for (int r = 0; r < gridCount; r++) {
      for (int c = 0; c < gridCount; c++) {
        newGrid[r][c] = grid[c][r];
      }
    }
    grid = newGrid;
  }

  Future<void> _exitGame() async {
    await _saveScore();
    _showDialog(over: false);
  }

  Future<void> _saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    int bestScore = prefs.getInt('bestScore2048') ?? 0;
    if (score > bestScore) {
      await prefs.setInt('bestScore2048', score);
      await prefs.setInt(
          'bestScoreTime2048', DateTime.now().millisecondsSinceEpoch);
    }
    await prefs.setBool('played-$todayKey', true);
  }

  void _checkGameOver() async {
    if (!_canMove()) {
      gameOver = true;
      await _saveScore();
      _showDialog(over: true);
    }
  }

  void _showDialog({required bool over}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(over ? "Game Over!" : "Exit Game?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Your Score: $score"),
            const SizedBox(height: 8),
            Text(
              score >= 1024
                  ? "Excellent! 🎉"
                  : score >= 512
                  ? "Good Job! 👍"
                  : "Keep Practicing! 💪",
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, score);
            },
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  Offset? _startSwipe;

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width - 30;
    final double h = MediaQuery.of(context).size.height - kToolbarHeight - 10;
    final double size = min(w, h);
    final double tileSpacing = 8;
    final double tileSize = (size - tileSpacing * (gridCount - 1)) / gridCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text("2048 Game"),
        backgroundColor: Colors.teal,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _exitGame),
      ),
      body: GestureDetector(
        onPanStart: (d) => _startSwipe = d.localPosition,
            onPanUpdate: (d) {
              if (_startSwipe == null || gameOver) return;
          final dx = d.localPosition.dx - _startSwipe!.dx;
          final dy = d.localPosition.dy - _startSwipe!.dy;
          if (dx.abs() > 30 || dy.abs() > 30) {
            if (dx.abs() > dy.abs()) {
              dx > 0 ? _moveRight() : _moveLeft();
            } else {
              dy > 0 ? _moveDown() : _moveUp();
            }
            _startSwipe = null;
          }
        },
        child: Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: gridCount * gridCount,
              itemBuilder: (ctx, index) {
                int r = index ~/ gridCount;
                int c = index % gridCount;
                int val = grid[r][c];

                return Container(
                  alignment: Alignment.center,
                  width: tileSize,
                  height: tileSize,
                  decoration: BoxDecoration(
                    color: getTileColor(val),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.4),
                        offset: const Offset(2, 2),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Text(
                    val == 0 ? '' : '$val',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: getTileTextColor(val)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Color getTileColor(int value) {
    switch (value) {
      case 0:
        return Colors.grey[300]!;
      case 2:
        return Colors.grey[200]!;
      case 4:
        return Colors.orange[100]!;
      case 8:
        return Colors.orange[300]!;
      case 16:
        return Colors.deepOrange[300]!;
      case 32:
        return Colors.deepOrange[400]!;
      case 64:
        return Colors.red[400]!;
      case 128:
        return Colors.yellow[400]!;
      case 256:
        return Colors.yellow[600]!;
      case 512:
        return Colors.green[400]!;
      case 1024:
        return Colors.green[600]!;
      case 2048:
        return Colors.blue[400]!;
      default:
        return Colors.black;
    }
  }

  Color getTileTextColor(int value) => value <= 4 ? Colors.black87 : Colors.white;
}
