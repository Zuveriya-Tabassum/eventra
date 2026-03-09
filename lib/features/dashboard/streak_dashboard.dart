// lib/features/dashboard/streak_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/services/streak_service.dart';

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

  Future<void> fetchStreakData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    if (mounted) setState(() => streak = (doc.data()?['streak'] ?? 0) as int);
  }

  Future<void> fetchLeaderboard() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').orderBy('streak', descending: true).limit(7).get();
    leaderboardDocs = snapshot.docs;
    userRank = -1;
    for (int i = 0; i < snapshot.docs.length; i++) {
      if (snapshot.docs[i].id == widget.userId) { userRank = i + 1; break; }
    }
    _controller.forward();
    if (mounted) setState(() {});
  }

  Future<void> fetchCalendar() async {
    final snap = await FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('login_history').get();
    final Map<String, Set<String>> temp = {};
    for (var doc in snap.docs) {
      final DateTime d = DateTime.parse(doc.id);
      final String key = DateFormat('yyyy-MM').format(d);
      temp.putIfAbsent(key, () => <String>{});
      temp[key]!.add(DateFormat('yyyy-MM-dd').format(d));
    }
    if (mounted) setState(() => monthlyLogins = temp);
  }

  Color rankColor(int r) {
    if (r == 1) return Colors.amber;
    if (r == 2) return Colors.blueGrey;
    if (r == 3) return Colors.brown;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Streak Dashboard"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: isWide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(children: [buildUserPosition(), const SizedBox(height: 16), buildLeaderboard()])),
                const SizedBox(width: 16),
                Expanded(child: Column(children: [buildStreak(true), const SizedBox(height: 16), buildCalendar(true)])),
              ])
            : Column(children: [
                buildUserPosition(), const SizedBox(height: 16),
                buildLeaderboard(), const SizedBox(height: 16),
                buildStreak(false), const SizedBox(height: 16),
                buildCalendar(false),
              ]),
      ),
    );
  }

  Widget buildUserPosition() {
    if (userRank == -1) return const SizedBox();
    return FadeTransition(
      opacity: _fade,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            const Icon(Icons.emoji_events, size: 40, color: Colors.amber),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Your Ranking", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("You are ranked #$userRank", style: const TextStyle(color: Colors.grey)),
            ]),
            const Spacer(),
            CircleAvatar(backgroundColor: rankColor(userRank), radius: 20, child: Text("#$userRank", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
          ]),
        ),
      ),
    );
  }

  Widget buildLeaderboard() {
    final int maxStreak = leaderboardDocs.isNotEmpty ? (leaderboardDocs[0]['streak'] ?? 1) : 1;
    return FadeTransition(
      opacity: _fade,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Top Performers", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            for (int i = 0; i < leaderboardDocs.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(children: [
                  CircleAvatar(radius: 18, backgroundColor: rankColor(i + 1), child: Text("${i + 1}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(leaderboardDocs[i]['name'] ?? "Anonymous", style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: ((leaderboardDocs[i]['streak'] ?? 0) as int) / maxStreak, minHeight: 6, backgroundColor: Colors.grey.shade100, color: rankColor(i + 1))),
                  ])),
                  const SizedBox(width: 12),
                  Text("${leaderboardDocs[i]['streak'] ?? 0}d", style: TextStyle(fontWeight: FontWeight.bold, color: rankColor(i + 1))),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  Widget buildStreak(bool wide) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        const Icon(Icons.local_fire_department, size: 60, color: Colors.orangeAccent),
        const SizedBox(height: 12),
        const Text("Current Streak", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
        Text("$streak Days", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
      ]),
    );
  }

  Widget buildCalendar(bool wide) {
    final String key = DateFormat('yyyy-MM').format(selectedMonth);
    final Set<String> active = monthlyLogins[key] ?? {};
    final int days = DateUtils.getDaysInMonth(selectedMonth.year, selectedMonth.month);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1))),
            Expanded(child: Center(child: Text(DateFormat('MMMM yyyy').format(selectedMonth), style: const TextStyle(fontWeight: FontWeight.bold)))),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1))),
          ]),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: days,
            itemBuilder: (_, i) {
              final date = DateTime(selectedMonth.year, selectedMonth.month, i + 1);
              final bool isActive = active.contains(DateFormat('yyyy-MM-dd').format(date));
              return Container(
                decoration: BoxDecoration(color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text("${i + 1}", style: TextStyle(color: isActive ? Colors.white : Colors.black54, fontWeight: isActive ? FontWeight.bold : FontWeight.normal))),
              );
            },
          )
        ]),
      ),
    );
  }
}
