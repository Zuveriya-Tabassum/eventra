// game.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/foundation.dart'; // for listEquals
import 'package:shared_preferences/shared_preferences.dart';

class Game2048 extends StatefulWidget {
  const Game2048({super.key});

  @override
  _Game2048State createState() => _Game2048State();
}

class _Game2048State extends State<Game2048> {
  static const int gridSize = 4;
  late List<List<int>> grid;
  int score = 0;
  int bestScore = 0;
  Offset startSwipeOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadBestScore().then((_) => resetGame());
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bestScore = prefs.getInt('bestScore2048') ?? 0;
    });
  }

  Future<void> _updateBestScore() async {
    if (score > bestScore) {
      bestScore = score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('bestScore2048', bestScore);
      setState(() {});
    }
  }

  void resetGame() {
    grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => 0));
    addRandomTile();
    addRandomTile();
    score = 0;
    setState(() {});
  }

  void addRandomTile() {
    List<Point<int>> empty = [];
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] == 0) empty.add(Point(i, j));
      }
    }
    if (empty.isNotEmpty) {
      final pos = empty[Random().nextInt(empty.length)];
      grid[pos.x][pos.y] = Random().nextInt(10) == 0 ? 4 : 2;
    }
  }

  bool moveLeft() {
    bool moved = false;
    for (int i = 0; i < gridSize; i++) {
      List<int> row = grid[i].where((x) => x != 0).toList();
      for (int j = 0; j < row.length - 1; j++) {
        if (row[j] == row[j + 1]) {
          row[j] *= 2;
          score += row[j];
          row[j + 1] = 0;
        }
      }
      row = row.where((x) => x != 0).toList();
      while (row.length < gridSize) row.add(0);
      if (!listEquals(grid[i], row)) moved = true;
      grid[i] = row;
    }
    return moved;
  }

  bool moveRight() {
    rotateGrid180();
    bool moved = moveLeft();
    rotateGrid180();
    return moved;
  }

  bool moveUp() {
    rotateGridLeft();
    bool moved = moveLeft();
    rotateGridRight();
    return moved;
  }

  bool moveDown() {
    rotateGridRight();
    bool moved = moveLeft();
    rotateGridLeft();
    return moved;
  }

  void rotateGridLeft() {
    List<List<int>> newGrid =
    List.generate(gridSize, (_) => List.generate(gridSize, (_) => 0));
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        newGrid[gridSize - j - 1][i] = grid[i][j];
      }
    }
    grid = newGrid;
  }

  void rotateGridRight() {
    List<List<int>> newGrid =
    List.generate(gridSize, (_) => List.generate(gridSize, (_) => 0));
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        newGrid[j][gridSize - i - 1] = grid[i][j];
      }
    }
    grid = newGrid;
  }

  void rotateGrid180() {
    rotateGridLeft();
    rotateGridLeft();
  }

  bool canMove() {
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] == 0) return true;
        if (j + 1 < gridSize && grid[i][j] == grid[i][j + 1]) return true;
        if (i + 1 < gridSize && grid[i][j] == grid[i + 1][j]) return true;
      }
    }
    return false;
  }

  void handleSwipe(Offset endSwipeOffset) {
    final dx = endSwipeOffset.dx - startSwipeOffset.dx;
    final dy = endSwipeOffset.dy - startSwipeOffset.dy;
    bool moved = false;

    if (dx.abs() > dy.abs()) {
      if (dx > 0) moved = moveRight();
      if (dx < 0) moved = moveLeft();
    } else {
      if (dy > 0) moved = moveDown();
      if (dy < 0) moved = moveUp();
    }

    if (moved) {
      addRandomTile();
      setState(() {});
      if (!canMove()) {
        // Game Over
        _updateBestScore();
        showDialog(
          context: context,
          builder: (_) =>
              AlertDialog(
                title: const Text('Game Over'),
                content: Text('Your score: $score\nBest: $bestScore'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      resetGame();
                    },
                    child: const Text('Restart'),
                  ),
                  TextButton(
                    onPressed: () {
                      _updateBestScore();
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(
                          score); // return score to caller
                    },
                    child: const Text('Exit'),
                  ),
                ],
              ),
        );
      }
    }
  }

  Color getTileColor(int value) {
    switch (value) {
      case 0:
        return Colors.grey[300]!;
      case 2:
        return Colors.orange[100]!;
      case 4:
        return Colors.orange[200]!;
      case 8:
        return Colors.orange[300]!;
      case 16:
        return Colors.orange[400]!;
      case 32:
        return Colors.orange[500]!;
      case 64:
        return Colors.orange[600]!;
      case 128:
        return Colors.orange[700]!;
      case 256:
        return Colors.orange[800]!;
      case 512:
        return Colors.orange[900]!;
      case 1024:
        return Colors.red[400]!;
      case 2048:
        return Colors.red[600]!;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _updateBestScore();
        Navigator.of(context).pop(score);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('2048 Game'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _updateBestScore();
                resetGame();
              },
            )
          ],
        ),
        body: GestureDetector(
          onPanStart: (details) {
            startSwipeOffset = details.localPosition;
          },
          onPanEnd: (details) {
            handleSwipe(details.velocity.pixelsPerSecond);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Score Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Score: $score',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    FutureBuilder<int>(
                      future: SharedPreferences.getInstance()
                          .then((prefs) => prefs.getInt('bestScore2048') ?? 0),
                      builder: (context, snapshot) {
                        int best = snapshot.data ?? 0;
                        return Text('Best: $best',
                            style: const TextStyle(
                                fontSize: 18, color: Colors.grey));
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Responsive squared grid (no scroll)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate the max square size to fit the grid within available width and height
                      double maxGridSize = constraints.maxWidth < constraints.maxHeight
                          ? constraints.maxWidth
                          : constraints.maxHeight;

                      // Calculate tile size with spacing considered
                      double tileSize = (maxGridSize - (gridSize - 1) * 5) / gridSize;

                      return Center(
                        child: SizedBox(
                          width: maxGridSize,
                          height: maxGridSize,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: gridSize * gridSize,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridSize,
                              mainAxisSpacing: 5,
                              crossAxisSpacing: 5,
                              childAspectRatio: 1,
                            ),
                            itemBuilder: (context, index) {
                              final x = index ~/ gridSize;
                              final y = index % gridSize;
                              final value = grid[x][y];

                              return Container(
                                width: tileSize,
                                height: tileSize,
                                decoration: BoxDecoration(
                                  color: getTileColor(value),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: value != 0
                                    ? Text(
                                  '$value',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                    : null,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}