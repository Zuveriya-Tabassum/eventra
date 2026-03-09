import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../announcements/ann_page.dart';
import '../events/hackathon_list.dart';
import 'streak_dashboard.dart';
import 'participant_dashboard.dart';
import '../contests/daily_contest.dart';
import '../events/workshop_list.dart';
import '../events/fests_list.dart';
import '../../core/presentation/app_drawer.dart';

final DateTime kEventStart = DateTime.utc(2026, 12, 25, 10, 0, 0);

class HomeScreen extends StatefulWidget {
  final bool isAdmin;

  const HomeScreen({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late Duration timeLeft;
  late Timer _timer;

  // 0 = Announcements, 1 = Home, 2 = Profile
  int _bottomIndex = 1;

  // daily‑visit flag (only once per day)
  bool _visitedTodayFlag = false;

  StreamSubscription? _announcementSubscription;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    timeLeft = kEventStart.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        timeLeft = kEventStart.difference(DateTime.now());
      });
    });

    _checkAndUpdateDailyVisit();
    _listenForNewAnnouncements();
  }

  void _listenForNewAnnouncements() {
    _announcementSubscription = FirebaseFirestore.instance
        .collection('announcements')
        .snapshots()
        .listen((snapshot) {
      if (!_initialLoadDone) {
        _initialLoadDone = true;
        return;
      }

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final title = data['title'] ?? 'New Announcement';
          _showNewAnnouncementSnackBar(title);
        }
      }
    });
  }

  void _showNewAnnouncementSnackBar(String title) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.campaign, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New Announcement!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.teal.shade700,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {
            setState(() => _bottomIndex = 0);
          },
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndUpdateDailyVisit();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _announcementSubscription?.cancel();
    super.dispose();
  }

  // ---------- DAILY VISIT / STREAK LOGIC ----------

  Future<void> _checkAndUpdateDailyVisit() async {
    if (_visitedTodayFlag) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() ?? {};

      int currentStreak = data['streak'] ?? 0;
      final String? lastVisitStr = data['lastVisitDate'];

      if (lastVisitStr == null) {
        currentStreak = 1;
      } else {
        final lastVisit = DateTime.parse(lastVisitStr);
        final lastDay = DateTime(
          lastVisit.year,
          lastVisit.month,
          lastVisit.day,
        );
        final diff = today.difference(lastDay).inDays;

        if (diff == 0) {
          // already counted today, nothing to do
          return;
        } else if (diff == 1) {
          currentStreak += 1;
        } else if (diff > 1) {
          currentStreak = 1;
        }
      }

      tx.update(userRef, {'streak': currentStreak, 'lastVisitDate': todayStr});

      final historyRef = userRef.collection('login_history').doc(todayStr);
      tx.set(historyRef, {
        'visited': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });

    if (mounted) {
      setState(() => _visitedTodayFlag = true);
    }
  }

  // ---------- UNREAD ANNOUNCEMENTS STREAM ----------
  Stream<int> _unreadAnnouncementsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<int>.value(0);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('announcement_state')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ---------- MAIN BUILD ----------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    Widget body;
    if (_bottomIndex == 1) {
      body = _homeTab(isWide, size);
    } else if (_bottomIndex == 0) {
      body = const AnnouncementPage();
    } else {
      body = const ParticipantDashboard();
    }

    return Scaffold(
      drawer: AppDrawer(
        currentIndex: _bottomIndex,
        onTabSelected: (i) => setState(() => _bottomIndex = i),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(child: body),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) => setState(() => _bottomIndex = i),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Announcements',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // ---------- HOME TAB ----------
  Widget _homeTab(bool isWide, Size size) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        if (widget.isAdmin)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _adminAnalytics(isWide),
            ),
          ),
        SliverToBoxAdapter(child: _featured(size.height * 0.25)),
        _quickGrid(isWide),
        const SliverToBoxAdapter(
          child: Padding(padding: EdgeInsets.symmetric(vertical: 12)),
        ),
      ],
    );
  }

  // ---------- APP BAR WITH BADGE ----------
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          Builder(
            builder: (c) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(c).openDrawer(),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Eventra',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const Spacer(),
          _dynamicStreakChip(),
          const SizedBox(width: 4),
          StreamBuilder<int>(
            stream: _unreadAnnouncementsStream(),
            builder: (context, snapshot) {
              final unread = snapshot.data ?? 0;
              final hasUnread = unread > 0;

              return Badge.count(
                count: unread,
                isLabelVisible: hasUnread,
                alignment: Alignment.topRight,
                backgroundColor: Colors.red,
                textColor: Colors.white,
                child: IconButton(
                  tooltip: 'Announcements',
                  icon: Icon(
                    Icons.notifications_none,
                    color: hasUnread ? Colors.amberAccent : Colors.white,
                  ),
                  onPressed: () {
                    setState(() => _bottomIndex = 0);
                  },
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
          GestureDetector(
            onTap: () => setState(() => _bottomIndex = 2),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                String? photoUrl;
                if (snapshot.hasData && snapshot.data!.data() != null) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  photoUrl = data['profileImage'];
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  // ---------- STREAK CHIP ----------
  Widget _dynamicStreakChip() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _streakChip(streak: 0);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int value = 0;
        if (snapshot.hasData && snapshot.data!.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          value = data['streak'] ?? 0;
        }
        return _streakChip(streak: value);
      },
    );
  }

  Widget _streakChip({required int streak}) {
    return InkWell(
      onTap: () {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StreakDashboard(userId: user.uid),
            ),
          );
        }
      },
      child: Chip(
        backgroundColor: Colors.white24,
        side: BorderSide.none,
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        avatar: const Icon(
          Icons.local_fire_department,
          size: 18,
          color: Colors.orange,
        ),
        label: Text('$streak', style: const TextStyle( fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ---------- ADMIN ANALYTICS ----------
  Widget _adminAnalytics(bool wide) {
    final stats = [
      ('Total', 32, Icons.event_available),
      ('Top', 5, Icons.trending_up),
      ('Boost', 4, Icons.trending_down),
    ];
    return Row(
      mainAxisAlignment: wide
          ? MainAxisAlignment.start
          : MainAxisAlignment.spaceBetween,
      children: stats
          .map(
            (s) => _analytic(title: s.$1, count: s.$2, icon: s.$3, wide: wide),
          )
          .toList(),
    );
  }

  Widget _analytic({
    required String title,
    required int count,
    required IconData icon,
    bool wide = false,
  }) {
    return Container(
      width: wide ? 150 : 110,
      height: 90,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          Text(
            '$count',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // ---------- FEATURED CARD ----------
  Widget _featured(double h) {
    return Container(
      height: h,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            'Eventra',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'More than notices — it\'s your campus story.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- QUICK GRID ----------
  SliverPadding _quickGrid(bool wide) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      sliver: SliverGrid.count(
        crossAxisCount: wide ? 6 : 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.0,
        children: [
          _quickTile(Icons.bolt, 'Hackathons', Colors.deepPurple),
          _quickTile(Icons.school, 'Workshops', Colors.orange),
          _quickTile(Icons.groups, 'Club\nActivities', Colors.pink),
          _quickTile(Icons.quiz, 'Daily contest', Colors.blue),
          _quickTile(Icons.layers, 'Announcements', Colors.teal),
          _quickTile(Icons.event_note, 'Fests', Colors.red),
        ],
      ),
    );
  }

  Widget _quickTile(IconData ic, String label, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (label == 'Hackathons') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HackathonListPage()),
            );
          } else if (label == 'Workshops') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkshopListPage()),
            );
          } else if (label.contains('Club')) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FestsListPage()),
            );
          } else if (label == 'Daily contest') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DailyContestPage()),
            );
          } else if (label == 'Announcements') {
            setState(() => _bottomIndex = 0);
          } else if (label == 'Fests') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FestsListPage()),
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.1), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(ic, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
