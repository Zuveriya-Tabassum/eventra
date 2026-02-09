import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔥 SAFE JSON DECODER
Map<String, dynamic> safeJsonDecode(String? raw) {
  if (raw == null || raw.isEmpty) {
    return {"name": "Player", "totalTime": 0, "games": {}};
  }

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {"name": "Player", "totalTime": 0, "games": {}};

    final result = <String, dynamic>{};
    decoded.forEach((key, value) => result[key.toString()] = value);

    final gamesRaw = result['games'];
    if (gamesRaw is Map) {
      final safeGames = <String, dynamic>{};
      gamesRaw.forEach((k, v) {
        safeGames[k.toString()] = v;
      });
      result['games'] = safeGames;
    } else {
      result['games'] = <String, dynamic>{};
    }

    result['name'] = result['name']?.toString() ?? 'Player';
    result['totalTime'] = result['totalTime'] ?? 0;
    return result;
  } catch (e) {
    print("JSON ERROR: $e, raw: $raw");
    return {"name": "Player", "totalTime": 0, "games": {}};
  }
}

/// 🏆 STREAM CONTROLLER FOR LIVE LEADERBOARD
class LeaderboardStream {
  static final LeaderboardStream _instance = LeaderboardStream._internal();
  factory LeaderboardStream() => _instance;
  LeaderboardStream._internal();

  final _controller = StreamController<void>.broadcast();
  Stream<void> get stream => _controller.stream;
  void refresh() => _controller.add(null);
}

/// 💻 LEADERBOARD WIDGET
class DailyContestLeaderboardSection extends StatefulWidget {
  const DailyContestLeaderboardSection({super.key});

  @override
  State<DailyContestLeaderboardSection> createState() =>
      _DailyContestLeaderboardSectionState();
}

class _DailyContestLeaderboardSectionState
    extends State<DailyContestLeaderboardSection>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> leaderboard = [];
  late AnimationController _mottoController;
  late Animation<double> _fade;
  StreamSubscription<void>? _streamSubscription;

  String selectedGame = "All";
  DateTime? fromDate;
  DateTime? toDate;
  final List<String> gameFilters = ["All", "2048", "Word Search", "Memory Match", "Quiz"];

  String get todayKey {
    final d = DateTime.now();
    return "${d.year}-${d.month}-${d.day}";
  }

  String get todayMotto {
    final mottos = ["Skill Wins. Speed Decides.", "Every Second Counts.", "Play Smart. Rise Fast.", "Brains Beat Luck."];
    return mottos[DateTime.now().day % mottos.length];
  }

  @override
  void initState() {
    super.initState();
    _mottoController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _fade = Tween(begin: 0.4, end: 1.0).animate(_mottoController);

    _streamSubscription = LeaderboardStream().stream.listen((_) => _loadLeaderboard());
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _mottoController.dispose();
    super.dispose();
  }

  IconData _gameIcon(String game) {
    switch (game) {
      case '2048': return Icons.grid_on;
      case 'Word Search': return Icons.search;
      case 'Memory Match': return Icons.memory;
      case 'Quiz': return Icons.quiz;
      default: return Icons.videogame_asset;
    }
  }

  Widget _rankWidget(int rank) {
    if (rank == 0) return const Icon(Icons.emoji_events, color: Colors.amber, size: 30);
    if (rank == 1) return const Icon(Icons.emoji_events, color: Colors.grey, size: 26);
    if (rank == 2) return const Icon(Icons.emoji_events, color: Colors.brown, size: 24);
    return CircleAvatar(radius: 14, backgroundColor: Colors.teal, child: Text("${rank + 1}", style: const TextStyle(color: Colors.white)));
  }

  Future<void> _loadLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith("player_")).toList();
    final Map<String, Map<String, dynamic>> playerDataMap = {};

    for (final key in keys) {
      try {
        final raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) continue;

        final data = safeJsonDecode(raw);
        final gamesRaw = data['games'] ?? {};
        final games = <String, Map<String, dynamic>>{};
        (gamesRaw as Map).forEach((k, v) {
          final gameData = Map<String, dynamic>.from(v);
          if (gameData['score'] is int) games[k] = gameData;
        });

        final name = data['name'] ?? 'Player';
        if (!playerDataMap.containsKey(name)) playerDataMap[name] = {"totalScore": 0, "games": {}};

        int totalScore = 0;
        games.forEach((gameName, gameData) {
          if (selectedGame != "All" && selectedGame != gameName) return;
          final score = gameData['score'] as int;
          totalScore += score;

          final existingGame = playerDataMap[name]!['games'][gameName];
          if (existingGame == null) {
            playerDataMap[name]!['games'][gameName] = gameData;
          } else {
            final existingScore = existingGame['score'] as int;
            playerDataMap[name]!['games'][gameName] = {...gameData, 'score': max(existingScore, score)};
          }
        });

        playerDataMap[name]!['totalScore'] += totalScore;
      } catch (_) {}
    }

    final temp = playerDataMap.entries.map((e) => {
      "name": e.key,
      "totalScore": e.value['totalScore'],
      "games": e.value['games'],
    }).toList()
      ..sort((a, b) => (b['totalScore'] as int).compareTo(a['totalScore'] as int));

    if (mounted) setState(() => leaderboard = temp);
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => fromDate = picked);
      _loadLeaderboard();
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => toDate = picked);
      _loadLeaderboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Leaderboard 🏆", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        FadeTransition(opacity: _fade, child: Text(todayMotto)),
        const SizedBox(height: 12),

        // Date + Game Filter
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: _pickFromDate,
                      child: Text(fromDate == null ? "From Date" : "${fromDate!.year}-${fromDate!.month}-${fromDate!.day}"),
                    ),
                  ),
                  const SizedBox(width: 3),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: _pickToDate,
                      child: Text(toDate == null ? "To Date" : "${toDate!.year}-${toDate!.month}-${toDate!.day}"),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<String>(
                value: selectedGame,
                items: gameFilters.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) {
                  setState(() => selectedGame = v!);
                  _loadLeaderboard();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Leaderboard
        if (leaderboard.isEmpty) const Center(child: Text("No players yet"))
        else ...List.generate(leaderboard.length, (i) => _playerCard(leaderboard[i], i)),
      ],
    );
  }

  Widget _playerCard(Map<String, dynamic> player, int rank) {
    final games = Map<String, dynamic>.from(player['games']);
    final topScore = games.values.map<int>((g) => g['score'] as int).fold(0, (prev, s) => max(prev, s));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        leading: _rankWidget(rank),
        title: Text(player['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text("${player['totalScore']} pts", style: const TextStyle(color: Colors.teal)),
        children: games.entries.map((e) {
          final g = Map<String, dynamic>.from(e.value);
          final isTop = g['score'] == topScore;
          return ListTile(
            leading: Icon(_gameIcon(e.key), color: isTop ? Colors.amber : Colors.teal),
            title: Text(e.key),
            trailing: Text("${g['score']} pts"),
            tileColor: isTop ? Colors.amber.withOpacity(0.15) : null,
          );
        }).toList(),
      ),
    );
  }
}

/// 💾 HELPER TO SAVE SCORES
class DailyContestLeaderboardSectionStateHelper {
  static String get todayKey {
    final d = DateTime.now();
    return "${d.year}-${d.month}-${d.day}";
  }

  static Future<void> save({
    required String playerId,
    required String playerName,
    required String gameName,
    required int score,
    required int timeSpentSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Add player to today's list
    List<String> ids = prefs.getStringList("daily_players_$todayKey") ?? [];
    if (!ids.contains(playerId)) ids.add(playerId);
    await prefs.setStringList("daily_players_$todayKey", ids);

    // Load existing player data
    final raw = prefs.getString("player_${playerId}_$todayKey");
    Map<String, dynamic> playerData = raw != null ? safeJsonDecode(raw) : {"name": playerName, "totalTime": 0, "games": {}};

    Map<String, dynamic> games = Map<String, dynamic>.from(playerData['games'] ?? {});
    games[gameName] = {
      "score": score,
      "best": (games[gameName]?['best'] ?? 0) < score ? score : games[gameName]?['best'] ?? 0,
      "played": true,
    };
    playerData['games'] = games;
    playerData['totalTime'] = (playerData['totalTime'] ?? 0) + timeSpentSeconds;

    await prefs.setString("player_${playerId}_$todayKey", jsonEncode(playerData));

    // Refresh leaderboard
    LeaderboardStream().refresh();
  }
}
