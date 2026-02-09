import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'admin_user_list_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  final VoidCallback onToggleTheme;
  final bool isDark;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  late TabController _rangeTabController; // Weekly / Monthly / Yearly

  @override
  void initState() {
    super.initState();
    _rangeTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _rangeTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: const Color(0xFFF1FBF7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.teal,
          actions: [
            IconButton(
              icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: widget.onToggleTheme,
            ),
            if (user != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Text(
                    user.email ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
        body: ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFE0F7F4),
                        Color(0xFFF8FFFE),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopOverviewRow(),
                      const SizedBox(height: 18),
                      _buildSecondaryRow(context),
                      const SizedBox(height: 18),
                      _buildBottomRow(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── TOP CARDS (Users / Participants / Club Heads) ─────────────────

  Widget _buildTopOverviewRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        int totalUsers = 0;
        int participants = 0;
        int clubHeads = 0;

        if (snapshot.hasData) {
          totalUsers = snapshot.data!.docs.length;
          for (final d in snapshot.data!.docs) {
            final data = d.data() as Map<String, dynamic>;
            final role = (data['role'] ?? 'Participant') as String;
            if (role == 'Participant') participants++;
            if (role == 'Club Head') clubHeads++;
          }
        }

        return LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 900;
            final children = [
              _overviewCard(
                title: 'Total Users',
                value: totalUsers.toString(),
                color: Colors.teal,
                gradient: const LinearGradient(
                  colors: [Color(0xFF26A69A), Color(0xFF80CBC4)],
                ),
                icon: Icons.people,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminUserListPage(
                        filterType: UserFilterType.all,
                      ),
                    ),
                  );
                },
              ),
              _overviewCard(
                title: 'Participants',
                value: participants.toString(),
                color: Colors.deepOrange,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A65), Color(0xFFFFAB91)],
                ),
                icon: Icons.school,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminUserListPage(
                        filterType: UserFilterType.participants,
                      ),
                    ),
                  );
                },
              ),
              _overviewCard(
                title: 'Club Heads',
                value: clubHeads.toString(),
                color: Colors.indigo,
                gradient: const LinearGradient(
                  colors: [Color(0xFF5C6BC0), Color(0xFF9FA8DA)],
                ),
                icon: Icons.emoji_events,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminUserListPage(
                        filterType: UserFilterType.clubHeads,
                      ),
                    ),
                  );
                },
              ),
            ];

            return wide
                ? Row(
              children: [
                Expanded(child: children[0]),
                const SizedBox(width: 12),
                Expanded(child: children[1]),
                const SizedBox(width: 12),
                Expanded(child: children[2]),
              ],
            )
                : Column(
              children: [
                children[0],
                const SizedBox(height: 12),
                children[1],
                const SizedBox(height: 12),
                children[2],
              ],
            );
          },
        );
      },
    );
  }

  Widget _overviewCard({
    required String title,
    required String value,
    required Color color,
    required LinearGradient gradient,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 110,
            padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: gradient,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────── SECONDARY ROW (Line + Pie) ─────────────────

  Widget _buildSecondaryRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 900;
        final lineChartCard = _glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Overall Participation',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 32,
                    child: TabBar(
                      controller: _rangeTabController,
                      indicator: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.teal,
                      tabs: const [
                        Tab(text: 'Weekly'),
                        Tab(text: 'Monthly'),
                        Tab(text: 'Yearly'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: TabBarView(
                  controller: _rangeTabController,
                  children: const [
                    _ParticipationLineChart(range: ParticipationRange.week),
                    _ParticipationLineChart(range: ParticipationRange.month),
                    _ParticipationLineChart(range: ParticipationRange.year),
                  ],
                ),
              ),
            ],
          ),
        );

        final pieChartCard = _glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Event Type Distribution',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal),
              ),
              SizedBox(height: 12),
              SizedBox(height: 220, child: _EventTypePieChart()),
            ],
          ),
        );

        return wide
            ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: lineChartCard),
            const SizedBox(width: 16),
            Expanded(child: pieChartCard),
          ],
        )
            : Column(
          children: [
            lineChartCard,
            const SizedBox(height: 16),
            pieChartCard,
          ],
        );
      },
    );
  }

  // ───────────────── BOTTOM ROW (Leaderboard + Activity Summary) ─────────────────

  Widget _buildBottomRow() {
    final leaderboardCard = _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Top 5 Participants',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal),
          ),
          SizedBox(height: 10),
          _TopFiveLeaderboard(),
        ],
      ),
    );

    final activityCard = _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Recent Activities',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal),
          ),
          SizedBox(height: 10),
          _RecentActivitiesPanel(),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 900;
        return wide
            ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: leaderboardCard),
            const SizedBox(width: 16),
            Expanded(child: activityCard),
          ],
        )
            : Column(
          children: [
            leaderboardCard,
            const SizedBox(height: 16),
            activityCard,
          ],
        );
      },
    );
  }

  // ────────────────── Common glass card ──────────────────

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.78),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ───────────────── PARTICIPATION LINE CHART ─────────────────

enum ParticipationRange { week, month, year }

class _ParticipationLineChart extends StatelessWidget {
  const _ParticipationLineChart({required this.range});

  final ParticipationRange range;

  // range currently not used; we just show last N points from all docs
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('participation')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text('No participation data',
                style: TextStyle(color: Colors.grey)),
          );
        }

        // aggregate per date string
        final Map<String, Map<String, int>> byDate = {};
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final dateStr = (data['date'] ?? '') as String;
          if (dateStr.isEmpty) continue;
          byDate.putIfAbsent(
              dateStr, () => {'workshop': 0, 'hackathon': 0, 'quiz': 0});
          byDate[dateStr]!['workshop'] =
              byDate[dateStr]!['workshop']! + (data['workshop'] ?? 0) as int;
          byDate[dateStr]!['hackathon'] =
              byDate[dateStr]!['hackathon']! + (data['hackathon'] ?? 0) as int;
          byDate[dateStr]!['quiz'] =
              byDate[dateStr]!['quiz']! + (data['quiz'] ?? 0) as int;
        }

        final sortedKeys = byDate.keys.toList()..sort();
        final lastKeys =
        sortedKeys.length > 10 ? sortedKeys.sublist(sortedKeys.length - 10) : sortedKeys;

        final labels = <String>[];
        final workshopSpots = <FlSpot>[];
        final hackathonSpots = <FlSpot>[];
        final quizSpots = <FlSpot>[];

        for (int i = 0; i < lastKeys.length; i++) {
          final key = lastKeys[i];
          final totals = byDate[key]!;
          labels.add(key.substring(5)); // show MM-DD
          workshopSpots.add(
              FlSpot(i.toDouble(), (totals['workshop'] ?? 0).toDouble()));
          hackathonSpots.add(
              FlSpot(i.toDouble(), (totals['hackathon'] ?? 0).toDouble()));
          quizSpots
              .add(FlSpot(i.toDouble(), (totals['quiz'] ?? 0).toDouble()));
        }

        double maxY = 1;
        for (final s in [...workshopSpots, ...hackathonSpots, ...quizSpots]) {
          if (s.y > maxY) maxY = s.y;
        }

        return LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY + 1,
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      labels[i],
                      style: const TextStyle(fontSize: 9),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 9, color: Colors.teal),
                  ),
                ),
              ),
              topTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              _line(workshopSpots, Colors.orange),
              _line(hackathonSpots, Colors.deepPurple),
              _line(quizSpots, Colors.blue),
            ],
          ),
        );
      },
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.12)),
    );
  }
}

// ───────────────── EVENT TYPE PIE CHART ─────────────────

class _EventTypePieChart extends StatelessWidget {
  const _EventTypePieChart();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('events_attended')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        int workshops = 0;
        int hackathons = 0;
        int quizzes = 0;

        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final type = (data['event_type'] ?? '') as String;
          if (type == 'Workshop') workshops++;
          if (type == 'Hackathon') hackathons++;
          if (type == 'Quiz') quizzes++;
        }

        final total = workshops + hackathons + quizzes;
        if (total == 0) {
          return const Center(
            child: Text('No events yet',
                style: TextStyle(color: Colors.grey)),
          );
        }

        final sections = <PieChartSectionData>[
          PieChartSectionData(
            value: workshops.toDouble(),
            color: Colors.orange,
            title: 'W',
          ),
          PieChartSectionData(
            value: hackathons.toDouble(),
            color: Colors.deepPurple,
            title: 'H',
          ),
          PieChartSectionData(
            value: quizzes.toDouble(),
            color: Colors.blue,
            title: 'Q',
          ),
        ];

        return Column(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 34,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _legendDot('Workshop', Colors.orange),
                _legendDot('Hackathon', Colors.deepPurple),
                _legendDot('Quiz', Colors.blue),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

// ───────────────── TOP‑5 LEADERBOARD ─────────────────

class _TopFiveLeaderboard extends StatelessWidget {
  const _TopFiveLeaderboard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
      FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<_UserScore> scores = [];

        for (final userDoc in snapshot.data!.docs) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final role = (userData['role'] ?? 'Participant') as String;
          if (role != 'Participant') continue;

          final streak = (userData['streak'] ?? 0) as int;
          scores.add(_UserScore(
            uid: userDoc.id,
            name: (userData['name'] ?? 'Anonymous') as String,
            streak: streak,
          ));
        }

        return FutureBuilder<List<_UserScore>>(
          future: _attachEvents(scores),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final list =
            snap.data!..sort((a, b) => b.totalScore.compareTo(a.totalScore));
            final top = list!.take(5).toList();

            if (top.isEmpty) {
              return const Text('No participants yet',
                  style: TextStyle(color: Colors.grey));
            }

            final maxScore =
            top.first.totalScore == 0 ? 1 : top.first.totalScore;

            return Column(
              children: [
                for (int i = 0; i < top.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _leaderRow(top[i], i + 1, maxScore),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<List<_UserScore>> _attachEvents(
      List<_UserScore> base) async {
    for (final u in base) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .collection('events_attended')
          .get();

      for (final d in snap.docs) {
        final data = d.data() as Map<String, dynamic>;
        final type = (data['event_type'] ?? '') as String;
        if (type == 'Workshop') u.workshops++;
        if (type == 'Hackathon') u.hackathons++;
      }
    }
    return base;
  }

  Widget _leaderRow(_UserScore s, int rank, int maxScore) {
    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.amber;
    } else if (rank == 2) {
      rankColor = Colors.blueGrey;
    } else if (rank == 3) {
      rankColor = Colors.brown;
    } else {
      rankColor = Colors.teal;
    }

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: rankColor,
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: s.totalScore / maxScore,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: rankColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${s.totalScore}',
              style: TextStyle(
                  color: rankColor, fontWeight: FontWeight.bold),
            ),
            Text(
              '${s.workshops}W ${s.hackathons}H • ${s.streak}🔥',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

class _UserScore {
  final String uid;
  final String name;
  int workshops = 0;
  int hackathons = 0;
  int streak;
  _UserScore({
    required this.uid,
    required this.name,
    required this.streak,
  });

  int get totalScore => workshops + hackathons + streak;
}

// ───────────────── RECENT ACTIVITIES ─────────────────

class _RecentActivitiesPanel extends StatelessWidget {
  const _RecentActivitiesPanel();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('events_attended')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Text('No activities yet',
              style: TextStyle(color: Colors.grey));
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = (data['event_type'] ?? '') as String;
            final name = (data['event_name'] ?? 'Event') as String;
            final date = (data['date'] ?? '') as String;
            final venue = (data['venue'] ?? '') as String;

            IconData icon;
            Color color;
            if (type == 'Hackathon') {
              icon = Icons.bolt;
              color = Colors.deepPurple;
            } else if (type == 'Workshop') {
              icon = Icons.school;
              color = Colors.orange;
            } else {
              icon = Icons.emoji_events;
              color = Colors.teal;
            }

            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.14),
                child: Icon(icon, color: color),
              ),
              title: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                '$type • $date • $venue',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: Colors.black54),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
