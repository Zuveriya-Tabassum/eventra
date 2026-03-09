import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

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
      gamesRaw.forEach((k, v) => safeGames[k.toString()] = v);
      result['games'] = safeGames;
    } else {
      result['games'] = <String, dynamic>{};
    }
    result['name'] = result['name']?.toString() ?? 'Player';
    result['totalTime'] = result['totalTime'] ?? 0;
    return result;
  } catch (e) {
    return {"name": "Player", "totalTime": 0, "games": {}};
  }
}

class LeaderboardStream {
  static final LeaderboardStream _instance = LeaderboardStream._internal();
  factory LeaderboardStream() => _instance;
  LeaderboardStream._internal();
  final _controller = StreamController<void>.broadcast();
  Stream<void> get stream => _controller.stream;
  void refresh() => _controller.add(null);
}

class DailyContestLeaderboardSection extends StatefulWidget {
  const DailyContestLeaderboardSection({super.key});
  @override
  State<DailyContestLeaderboardSection> createState() => _DailyContestLeaderboardSectionState();
}

class _DailyContestLeaderboardSectionState extends State<DailyContestLeaderboardSection> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> leaderboard = [];
  late AnimationController _mottoController;
  StreamSubscription<void>? _streamSubscription;
  String selectedGame = "All";
  final List<String> gameFilters = ["All", "2048", "Word Search", "Memory Match", "Quiz"];

  @override
  void initState() {
    super.initState();
    _mottoController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _streamSubscription = LeaderboardStream().stream.listen((_) => _loadLeaderboard());
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _mottoController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith("player_")).toList();
    final Map<String, Map<String, dynamic>> playerDataMap = {};
    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) continue;
      final data = safeJsonDecode(raw);
      final name = data['name'] ?? 'Player';
      final games = Map<String, dynamic>.from(data['games'] ?? {});
      if (!playerDataMap.containsKey(name)) playerDataMap[name] = {"totalScore": 0, "games": {}};
      int totalScore = 0;
      games.forEach((gameName, gameData) {
        if (selectedGame != "All" && !gameName.contains(selectedGame)) return;
        totalScore += (gameData['score'] ?? 0) as int;
        playerDataMap[name]!['games'][gameName] = gameData;
      });
      playerDataMap[name]!['totalScore'] += totalScore;
    }
    final temp = playerDataMap.entries.map((e) => {"name": e.key, "totalScore": e.value['totalScore'], "games": e.value['games']}).toList()
      ..sort((a, b) => (b['totalScore'] as int).compareTo(a['totalScore'] as int));
    if (mounted) setState(() => leaderboard = temp);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Leaderboard", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(
              width: 120,
              child: DropdownButton<String>(
                value: selectedGame,
                isExpanded: true,
                underline: const SizedBox(),
                items: gameFilters.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (v) { setState(() => selectedGame = v!); _loadLeaderboard(); },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (leaderboard.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No entries yet", style: TextStyle(color: Colors.grey))))
        else ...List.generate(leaderboard.length, (i) => _playerCard(leaderboard[i], i)),
      ],
    );
  }

  Widget _playerCard(Map<String, dynamic> player, int rank) {
    final bool isTop = rank < 3;
    final Color rankColor = isTop ? (rank == 0 ? Colors.amber : (rank == 1 ? Colors.grey : Colors.brown)) : Colors.blueGrey.shade100;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: rankColor, radius: 18, child: Text("${rank + 1}", style: TextStyle(color: isTop ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14))),
        title: Text(player['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text("${player['totalScore']} pts", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class DailyContestLeaderboardSectionStateHelper {
  static String get todayKey => "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
  static Future<void> save({required String playerId, required String playerName, required String gameName, required int score, required int timeSpentSeconds}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("player_${playerId}_$todayKey");
    Map<String, dynamic> playerData = raw != null ? safeJsonDecode(raw) : {"name": playerName, "totalTime": 0, "games": {}};
    Map<String, dynamic> games = Map<String, dynamic>.from(playerData['games'] ?? {});
    games[gameName] = {"score": score, "played": true};
    playerData['games'] = games;
    playerData['totalTime'] = (playerData['totalTime'] ?? 0) + timeSpentSeconds;
    await prefs.setString("player_${playerId}_$todayKey", jsonEncode(playerData));
    LeaderboardStream().refresh();
  }
}
