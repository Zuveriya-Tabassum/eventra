import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ann_page.dart';
import 'login_screen.dart';
import 'hackathon_list.dart';
import 'streak_dashboard.dart';
import 'participant_dashboard.dart';
import 'club.dart';
import '../daily_contest.dart';
import 'workshop_list.dart';

final DateTime kEventStart = DateTime.utc(2026, 12, 25, 10, 0, 0);

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;
  final bool isAdmin;

  const HomeScreen({
    Key? key,
    required this.onToggleTheme,
    required this.isDark,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  late Duration timeLeft;
  late Timer _timer;

  String _searchQuery = '';
  String _filter = 'All';

  // 0 = Announcements, 1 = Home, 2 = Profile
  int _bottomIndex = 1;

  // daily‑visit flag (only once per day)
  bool _visitedTodayFlag = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    timeLeft = kEventStart.difference(DateTime.now());
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        setState(() {
          timeLeft = kEventStart.difference(DateTime.now());
        });
      },
    );

    _checkAndUpdateDailyVisit();
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

    final userRef =
    FirebaseFirestore.instance.collection('users').doc(user.uid);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() as Map<String, dynamic>? ?? {};

      int currentStreak = data['streak'] ?? 0;
      final String? lastVisitStr = data['lastVisitDate'];

      if (lastVisitStr == null) {
        currentStreak = 1;
      } else {
        final lastVisit = DateTime.parse(lastVisitStr);
        final lastDay =
        DateTime(lastVisit.year, lastVisit.month, lastVisit.day);
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

      tx.update(userRef, {
        'streak': currentStreak,
        'lastVisitDate': todayStr,
      });

      final historyRef =
      userRef.collection('login_history').doc(todayStr);
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

  final List<Map<String, String>> _allEvents = const [
    {
      'title': 'Flutter Workshop',
      'desc': 'Hands-on mobile dev session.',
      'type': 'Workshop',
      'img':
      'https://images.unsplash.com/photo-1581093588401-90ac6b69423c?auto=format&fit=crop&w=800&q=60'
    },
    {
      'title': 'AI Quiz League',
      'desc': 'Compete with AI enthusiasts.',
      'type': 'Daily contest',
      'img':
      'https://images.unsplash.com/photo-1551836022-d5d88e9218df?auto=format&fit=crop&w=800&q=60'
    },
    {
      'title': 'Campus Hack 2025',
      'desc': '24‑hour coding sprint.',
      'type': 'Hackathon',
      'img':
      'https://images.unsplash.com/photo-1542831371-d531d36971e6?auto=format&fit=crop&w=800&q=60'
    },
  ];

  List<Map<String, String>> get _visibleEvents => _allEvents.where((ev) {
    final matchSearch = ev['title']!
        .toLowerCase()
        .contains(_searchQuery.toLowerCase());
    final matchFilter = _filter == 'All' ? true : ev['type'] == _filter;
    return matchSearch && matchFilter;
  }).toList();

  // ---------- MAIN BUILD ----------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    Widget body;
    if (_bottomIndex == 1) {
      body = _homeTab(isWide, size);
    } else if (_bottomIndex == 0) {
      body = AnnouncementPage(
        onToggleTheme: widget.onToggleTheme,
      );
    } else {
      body = const ParticipantDashboard();
    }

    return Scaffold(
      drawer: _buildDrawer(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(child: body),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) => setState(() => _bottomIndex = i),
        selectedItemColor: Colors.teal,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Announcements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            child: Text(
              '',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        _quickGrid(isWide),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }

  // ---------- DRAWER ----------
  Drawer _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.teal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                CircleAvatar(radius: 28, backgroundColor: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Eventra Menu',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_filled, color: Colors.teal),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _bottomIndex = 1);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bolt, color: Colors.teal),
            title: const Text('Hackathons'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HackathonListPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.school, color: Colors.teal),
            title: const Text('Workshops'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WorkshopListPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.groups, color: Colors.teal),
            title: const Text('Club Activities'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ClubHubHomePage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.quiz, color: Colors.teal),
            title: const Text('Daily contest'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DailyContestPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.layers, color: Colors.teal),
            title: const Text('Announcements'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnnouncementPage(
                    onToggleTheme: widget.onToggleTheme,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_fire_department,
                color: Colors.deepOrange),
            title: const Text('Streak dashboard'),
            onTap: () {
              Navigator.pop(context);
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        StreakDashboard(userId: user.uid),
                  ),
                );
              }
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---------- APP BAR WITH BADGE ----------
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.teal,
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
            tooltip: 'Toggle theme',
            icon: Icon(
              widget.isDark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: widget.onToggleTheme,
          ),
          GestureDetector(
            onTap: () => setState(() => _bottomIndex = 2),
            child: const CircleAvatar(
              radius: 18,
              backgroundImage:
              NetworkImage('https://i.pravatar.cc/150?img=4'),
            ),
          ),
          const SizedBox(width: 8),
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
        backgroundColor: Colors.orange.shade100,
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        avatar: const Icon(
          Icons.local_fire_department,
          size: 18,
          color: Colors.orange,
        ),
        label: Text(
          '$streak',
          style: const TextStyle(color: Colors.black),
        ),
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
      mainAxisAlignment:
      wide ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
      children: stats
          .map(
            (s) => _analytic(
          title: s.$1,
          count: s.$2,
          icon: s.$3,
          wide: wide,
        ),
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
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(icon, color: Colors.teal),
          Text(
            '$count',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700),
          ),
          Text(title),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _GradientText('Eventra', size: 32),
          SizedBox(height: 10),
          Text(
            'More than notices — it\'s your campus story.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
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
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
        children: [
          _quickTile(Icons.bolt, 'Hackathons'),
          _quickTile(Icons.school, 'Workshops'),
          _quickTile(Icons.groups, 'Club\nActivities'),
          _quickTile(Icons.quiz, 'Daily contest'),
          _quickTile(Icons.layers, 'Announcements'),
          _quickTile(Icons.event_note, 'Fests'),
        ],
      ),
    );
  }

  Widget _quickTile(IconData ic, String label) {
    const photos = {
      'Hackathons':
      'https://cdn.dribbble.com/userupload/22803462/file/original-c8e0d2ce8435353e386bf621e0e9c410.gif',
      'Workshops':
      'https://cdn.dribbble.com/userupload/20282516/file/original-a94a7235de230dbb66ffd697473f8b36.gif',
      'Club\nActivities':
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTBuE8lKn_vkrUj-N0fhzVIur3JwHA9d2eToF6wQXrbSxA3zp5Ean8gxwv35OLkU4ALQ6M&usqp=CAU',
      'Daily contest':
      'https://cdn.pixabay.com/animation/2022/11/01/18/38/18-38-04-285_512.gif',
      'Announcements':
      'https://assets-v2.lottiefiles.com/a/79bf2f40-1174-11ee-9faf-fb0a1e9de6a4/NNsGv4eVNs.gif',
      'Fests':
      'https://assets-v2.lottiefiles.com/a/396a815c-1164-11ee-ab1f-673accc5fb2e/Nu8f6ibV0J.gif',
    };
    final w = MediaQuery.of(context).size.width;
    final fallback =
        'https://images.unsplash.com/photo-1515169067865-5387ec356754?auto=format&fit=crop&w=600&q=60';
    final img = w < 450 ? fallback : (photos[label] ?? fallback);

    return InkWell(
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
            MaterialPageRoute(builder: (_) => const ClubHubHomePage()),
          );
        } else if (label == 'Daily contest') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailyContestPage()),
          );
        } else if (label == 'Announcements') {
          setState(() => _bottomIndex = 0);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          image: DecorationImage(image: NetworkImage(img), fit: BoxFit.cover),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.black.withOpacity(0.45),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(ic, color: Colors.white, size: 28),
              const SizedBox(height: 6),
              Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubble(IconData ic) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Ink(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(ic, size: 22, color: Colors.teal),
      ),
    );
  }
}

// ---------- GRADIENT TEXT ----------
class _GradientText extends StatelessWidget {
  final String text;
  final double size;

  const _GradientText(this.text, {this.size = 30});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF147B8E), Color(0xFF2BB673)],
      ).createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
