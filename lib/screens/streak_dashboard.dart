import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../services/streak_service.dart';

class StreakDashboard extends StatefulWidget {
  final String userId;
  const StreakDashboard({Key? key, required this.userId}) : super(key: key);

  @override
  State<StreakDashboard> createState() => _StreakDashboardState();
}

class _StreakDashboardState extends State<StreakDashboard>
    with SingleTickerProviderStateMixin {
  int streak = 0;
  int userRank = -1;

  List<QueryDocumentSnapshot> leaderboardDocs = [];
  Map<String, Set<String>> monthlyLogins = {};

  DateTime selectedMonth = DateTime.now();

  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    // Ensure streak is updated for today, then load data.
    StreakService.updateDailyStreak(widget.userId).then((_) {
      fetchStreakData();
      fetchLeaderboard();
      fetchCalendar();
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ================= DATA =================

  Future<void> fetchStreakData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    setState(() {
      streak = (doc.data()?['streak'] ?? 0) as int;
    });
  }

  Future<void> fetchLeaderboard() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('streak', descending: true)
        .limit(7)
        .get();

    leaderboardDocs = snapshot.docs;

    userRank = -1;
    for (int i = 0; i < snapshot.docs.length; i++) {
      if (snapshot.docs[i].id == widget.userId) {
        userRank = i + 1;
        break;
      }
    }

    _controller.forward();
    setState(() {});
  }

  Future<void> fetchCalendar() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('login_history')
        .get();

    final Map<String, Set<String>> temp = {};
    for (var doc in snap.docs) {
      final DateTime d = DateTime.parse(doc.id); // yyyy-MM-dd
      final String key = DateFormat('yyyy-MM').format(d);
      temp.putIfAbsent(key, () => <String>{});
      temp[key]!.add(DateFormat('yyyy-MM-dd').format(d));
    }

    setState(() => monthlyLogins = temp);
  }

  // ================= HELPERS =================

  Color rankColor(int r) {
    if (r == 1) return Colors.amber;
    if (r == 2) return Colors.blueGrey;
    if (r == 3) return Colors.brown;
    return Colors.teal;
  }

  String rankEmoji(int r) {
    if (r == 1) return "🥇";
    if (r == 2) return "🥈";
    if (r == 3) return "🥉";
    return "🔥";
  }

  // ================= UI =================

  Widget buildUserPosition() {
    if (userRank == -1) return const SizedBox();
    return FadeTransition(
      opacity: _fade,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Text(rankEmoji(userRank), style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(
                "Your Position",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                "You are ranked #$userRank",
                style: const TextStyle(fontSize: 14),
              ),
            ]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: rankColor(userRank),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                "#",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              "$userRank",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget buildLeaderboard() {
    final int maxStreak =
    leaderboardDocs.isNotEmpty ? (leaderboardDocs[0]['streak'] ?? 1) : 1;

    return FadeTransition(
      opacity: _fade,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Top 7 Performers",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < leaderboardDocs.length && i < 7; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: rankColor(i + 1),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "${i + 1}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              leaderboardDocs[i]['name'] ?? "Anonymous",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              leaderboardDocs[i]['studentId'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Stack(
                              children: [
                                Container(
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double streakValue =
                                    (leaderboardDocs[i]['streak'] ?? 0)
                                        .toDouble();
                                    final double widthFactor =
                                    (streakValue / maxStreak)
                                        .clamp(0.0, 1.0);

                                    return AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 600),
                                      width:
                                      constraints.maxWidth * widthFactor,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: rankColor(i + 1),
                                        borderRadius:
                                        BorderRadius.circular(10),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${leaderboardDocs[i]['streak'] ?? 0} days",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[800],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStreak(bool wide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: wide ? 14 : 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade200, Colors.orange.shade50],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(children: [
        const Icon(Icons.local_fire_department,
            size: 52, color: Colors.deepOrange),
        const SizedBox(height: 6),
        const Text("Current Streak",
            style: TextStyle(fontWeight: FontWeight.w600)),
        Text("$streak days",
            style: TextStyle(
                fontSize: wide ? 22 : 34, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget buildCalendar(bool wide) {
    final String key = DateFormat('yyyy-MM').format(selectedMonth);
    final Set<String> active = monthlyLogins[key] ?? {};
    final int days =
    DateUtils.getDaysInMonth(selectedMonth.year, selectedMonth.month);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => selectedMonth =
                  DateTime(selectedMonth.year, selectedMonth.month - 1)),
            ),
            Expanded(
              child: Center(
                child: Text(
                  DateFormat('MMMM yyyy').format(selectedMonth),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => selectedMonth =
                  DateTime(selectedMonth.year, selectedMonth.month + 1)),
            ),
          ]),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: wide ? 1.4 : 1,
            ),
            itemCount: days,
            itemBuilder: (_, i) {
              final date = DateTime(
                  selectedMonth.year, selectedMonth.month, i + 1);
              final String keyDay = DateFormat('yyyy-MM-dd').format(date);
              final bool activeDay = active.contains(keyDay);
              return Container(
                decoration: BoxDecoration(
                  color: activeDay ? Colors.teal : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "${i + 1}",
                    style: TextStyle(
                      color:
                      activeDay ? Colors.white : Colors.black54,
                    ),
                  ),
                ),
              );
            },
          )
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF6),
      appBar: AppBar(
        title: const Text("Streak Dashboard"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding:
        EdgeInsets.symmetric(horizontal: isWide ? 8 : 16, vertical: 16),
        child: isWide
            ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(children: [
                buildUserPosition(),
                const SizedBox(height: 16),
                buildLeaderboard(),
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(children: [
                buildStreak(true),
                const SizedBox(height: 16),
                buildCalendar(true),
              ]),
            ),
          ],
        )
            : Column(children: [
          buildUserPosition(),
          const SizedBox(height: 16),
          buildLeaderboard(),
          const SizedBox(height: 16),
          buildStreak(false),
          const SizedBox(height: 16),
          buildCalendar(false),
        ]),
      ),
    );
  }
}
