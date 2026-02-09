// imports at the top of the file
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'streak_dashboard.dart';
import 'hackathon_list.dart';
import 'workshop_list.dart';
import 'events.dart';

class ParticipantDashboard extends StatefulWidget {
  const ParticipantDashboard({Key? key}) : super(key: key);

  @override
  State<ParticipantDashboard> createState() => _ParticipantDashboardState();
}

class _ParticipantDashboardState extends State<ParticipantDashboard> {
  User? user;
  bool _isEditing = false;
  File? _imageFile;
  String? _profileImageUrl;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _departmentController = TextEditingController();
  final _yearController = TextEditingController();

  // filter for enrolled events list
  String _enrolledFilter = 'All';

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _departmentController.text = data['department'] ?? '';
          _yearController.text = data['year'] ?? '';
          _profileImageUrl = data['profileImage'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
    await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({
      'name': _nameController.text,
      'phone': _phoneController.text,
      'bio': _bioController.text,
      'department': _departmentController.text,
      'year': _yearController.text,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Please login to see your dashboard.",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      );
    }

    final userId = user!.uid;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          !_isEditing
              ? IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => setState(() => _isEditing = true),
          )
              : IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF53C6BE),
              Color(0xFFE7FCFF),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .snapshots(),
            builder: (context, snapshot) {
              int streak = 0;
              if (snapshot.hasData && snapshot.data!.data() != null) {
                final data =
                snapshot.data!.data() as Map<String, dynamic>;
                streak = data['streak'] ?? 0;
                _profileImageUrl ??= data['profileImage'];
              }

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 45,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(40, 32, 8, 32),
                        child: _glassBox(
                          child: _buildProfileColumn(
                              context, streak, userId, true),
                          blur: 18,
                          bg: Colors.white.withOpacity(0.25),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 55,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(8, 32, 40, 32),
                        child: _glassBox(
                          child: _buildAnalyticsColumn(userId),
                          blur: 18,
                          bg: Colors.white.withOpacity(0.25),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _glassBox(
                        child: _buildProfileColumn(
                            context, streak, userId, false),
                        blur: 18,
                        bg: Colors.white.withOpacity(0.27),
                      ),
                      const SizedBox(height: 25),
                      _glassBox(
                        child: _buildAnalyticsColumn(userId),
                        blur: 18,
                        bg: Colors.white.withOpacity(0.27),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _glassBox({
    required Widget child,
    double blur = 12,
    Color? bg,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          color: bg ?? Colors.white.withOpacity(.17),
          padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: child,
        ),
      ),
    );
  }

  // ---------- PROFILE COLUMN ----------
  Widget _buildProfileColumn(
      BuildContext context, int streak, String userId, bool wide) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: wide ? 68 : 55,
                backgroundColor:
                Colors.teal.shade300.withOpacity(.23),
                child: CircleAvatar(
                  radius: wide ? 61 : 47,
                  backgroundColor:
                  Colors.white.withOpacity(.14),
                  child: CircleAvatar(
                    radius: wide ? 53 : 39,
                    backgroundColor:
                    Colors.white.withOpacity(.15),
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : null)
                    as ImageProvider?,
                    child: _imageFile == null &&
                        _profileImageUrl == null
                        ? const Icon(Icons.person,
                        size: 43, color: Colors.white)
                        : null,
                  ),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 2,
                  right: wide ? 40 : 22,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: const CircleAvatar(
                      backgroundColor: Colors.teal,
                      radius: 20,
                      child: Icon(Icons.camera_alt,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _isEditing
              ? TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              filled: true,
              fillColor: Colors.white70,
            ),
            validator: (v) =>
            v!.isEmpty ? 'Name required' : null,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: wide ? 26 : 20,
              color: Colors.teal.shade900,
              letterSpacing: 1.15,
            ),
          )
              : Text(
            _nameController.text.isEmpty
                ? 'Your Name'
                : _nameController.text,
            style: TextStyle(
              fontSize: wide ? 26 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal[900],
              letterSpacing: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            user?.email ?? '',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statChip(Icons.local_fire_department,
                  streak.toString(), Colors.orange),
              const SizedBox(width: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('login_history')
                    .snapshots(),
                builder: (context, snap) {
                  int logins = snap.hasData
                      ? snap.data!.docs.length
                      : 0;
                  return _statChip(
                      Icons.login, logins.toString(), Colors.blue);
                },
              ),
            ],
          ),
          const SizedBox(height: 19),
          _profileDetailRow(
              Icons.phone, "Phone", _phoneController, _isEditing),
          const SizedBox(height: 7),
          _profileDetailRow(Icons.school, "Department",
              _departmentController, _isEditing),
          const SizedBox(height: 7),
          _profileDetailRow(Icons.calendar_today, "Year",
              _yearController, _isEditing),
          const SizedBox(height: 7),
          _profileDetailRow(Icons.info_outline, "Bio",
              _bioController, _isEditing,
              maxLines: 3),
          const SizedBox(height: 19),
          ElevatedButton.icon(
            icon: const Icon(Icons.bar_chart),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            label: const Text(
              "View Streak Dashboard",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        StreakDashboard(userId: userId),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, Color color) {
    return Chip(
      label: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 16,
        ),
      ),
      avatar: Icon(icon, color: color, size: 20),
      backgroundColor: Colors.white.withOpacity(0.17),
      labelPadding:
      const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(3),
    );
  }

  Widget _profileDetailRow(
      IconData icon,
      String label,
      TextEditingController controller,
      bool isEditing, {
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: isEditing
          ? TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
          Icon(icon, color: Colors.teal.shade600),
          fillColor:
          Colors.white.withOpacity(.11),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          labelStyle:
          const TextStyle(color: Colors.black45),
        ),
      )
          : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: Colors.teal.shade800, size: 18),
          const SizedBox(width: 11),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.teal,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  TextSpan(
                    text: controller.text.isEmpty
                        ? 'Not provided'
                        : controller.text,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- ANALYTICS COLUMN ----------
  Widget _buildAnalyticsColumn(String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Text(
      'Your Event Participation',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: Colors.teal.shade800,
      ),
    ),
    const SizedBox(height: 10),
    _EnrollmentPieChart(userId: userId),
    const SizedBox(height: 16),
    _PerformanceLineChart(userId: userId),
    const SizedBox(height: 16),
    Wrap(
    spacing: 10,
    runSpacing: 8,
    children: [
    OutlinedButton.icon(
    icon: const Icon(Icons.bolt, size: 18),
    style: OutlinedButton.styleFrom(
    foregroundColor: Colors.deepPurple,
    side: BorderSide(
    color: Colors.deepPurple.shade200),
    padding: const EdgeInsets.symmetric(
    horizontal: 10, vertical: 8),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    ),
    ),
    label: const Text('View Hackathons'),
    onPressed: () {
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (_) => const HackathonListPage(),
    ),
    );
    },
    ),
    OutlinedButton.icon(
    icon: const Icon(Icons.school, size: 18),
    style: OutlinedButton.styleFrom(
    foregroundColor: Colors.orange,
    side: BorderSide(color: Colors.orange.shade200),
    padding: const EdgeInsets.symmetric(
    horizontal: 10, vertical: 8),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    ),
    ),
    label: const Text('View Workshops'),
    onPressed: () {
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (_) =>
    const WorkshopListPage(),
    ),
    );
    },
    ),
    OutlinedButton.icon(
    icon: const Icon(Icons.event_note, size: 18),
    style: OutlinedButton.styleFrom(
    foregroundColor: Colors.teal,
    side: BorderSide(color: Colors.teal.shade200),
    padding: const EdgeInsets.symmetric(
    horizontal: 10, vertical: 8),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    ),
    ),
    label: const Text('All Events'),
    onPressed: () {
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (_) => ClubEventListPage(
      isAdmin: false,
      currentUserId: userId,
    ),
    ),
    );
    },
    ),
    ],
    ),
        const SizedBox(height: 20),
        Text(
          'Enrolled Events',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.teal.shade800,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All'),
              const SizedBox(width: 6),
              _buildFilterChip('Hackathon'),
              const SizedBox(width: 6),
              _buildFilterChip('Workshop'),
              const SizedBox(width: 6),
              _buildFilterChip('Quiz'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _EnrolledEventsList(
          userId: userId,
          filter: _enrolledFilter,
        ),
        const SizedBox(height: 20),
        // Leaderboard Section
        FutureBuilder<Map<String, dynamic>>(
          future: _fetchLeaderboardData(userId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            final userRank = data['userRank'];
            final totalUsers = data['totalUsers'];
            final percentile = ((totalUsers - userRank + 1) / totalUsers * 100).round();
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Leaderboard Position',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events, size: 40, color: Colors.amber),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            Text(
                              '#$userRank of $totalUsers',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            Text(
                              'Top $percentile%',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _fetchLeaderboardData(String userId) async {
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();
    final users = usersSnap.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'score': data['totalScore'] ?? 0,  // Assuming totalScore is precomputed: 2*hackathons + workshops + quizzes
      };
    }).toList();
    users.sort((a, b) => b['score'].compareTo(a['score']));
    int userRank = users.indexWhere((u) => u['id'] == userId) + 1;
    return {
      'userRank': userRank,
      'totalUsers': users.length,
    };
  }

  Widget _buildFilterChip(String label) {
    final selected = _enrolledFilter == label;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.teal.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      selectedColor: Colors.teal.shade400,
      backgroundColor: Colors.white.withOpacity(0.8),
      onSelected: (_) {
        setState(() => _enrolledFilter = label);
      },
    );
  }
}

// ---------- PIE CHART (StreamBuilder, always visible) ----------
class _EnrollmentPieChart extends StatelessWidget {
  final String userId;
  const _EnrollmentPieChart({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('participation')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snap.data!.docs;
        int hack = 0, work = 0, quiz = 0;
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          hack += (data['hackathon'] ?? 0) as int;
          work += (data['workshop'] ?? 0) as int;
          quiz += (data['quiz'] ?? 0) as int;
        }

        return SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  value: hack.toDouble(),
                  color: Colors.deepPurple.shade200,
                  title: 'Hack\n$hack',
                  radius: 60,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PieChartSectionData(
                  value: work.toDouble(),
                  color: Colors.orange.shade200,
                  title: 'Work\n$work',
                  radius: 60,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PieChartSectionData(
                  value: quiz.toDouble(),
                  color: Colors.blue.shade200,
                  title: 'Quiz\n$quiz',
                  radius: 60,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------- PERFORMANCE LINE CHART (StreamBuilder, always visible) ----------
class _PerformanceLineChart extends StatelessWidget {
  final String userId;
  const _PerformanceLineChart({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('participation')
          .orderBy('date')
          .limitToLast(7)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snap.data!.docs;

        List<String> labels = [];
        List<FlSpot> scoreSpots = [];

        if (docs.isEmpty) {
          labels = List.generate(7, (i) => '--');
          scoreSpots =
              List.generate(7, (i) => FlSpot(i.toDouble(), 0.0));
        } else {
          labels = docs
              .map((d) => (d['date'] as String).substring(5))
              .toList();
          for (int i = 0; i < docs.length; i++) {
            final d = docs[i].data() as Map<String, dynamic>;
            final h = (d['hackathon'] ?? 0).toDouble();
            final w = (d['workshop'] ?? 0).toDouble();
            final q = (d['quiz'] ?? 0).toDouble();
            final score = 2 * h + w + q;
            scoreSpots.add(
                FlSpot(i.toDouble(), score.toDouble()));
          }
        }

        return SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.round();
                      if (i >= 0 && i < labels.length) {
                        return Text(
                          labels[i],
                          style:
                          const TextStyle(fontSize: 11),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              minY: 0,
              lineBarsData: [
                LineChartBarData(
                  spots: scoreSpots,
                  isCurved: true,
                  color: Colors.teal,
                  barWidth: 3,
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.teal.withOpacity(0.15),
                  ),
                  dotData: FlDotData(show: true),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------- ENROLLED EVENTS LIST WITH FILTER ----------
class _EnrolledEventsList extends StatelessWidget {
  final String userId;
  final String filter;
  const _EnrolledEventsList({
    required this.userId,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('enrollments')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs.where((doc) {
          if (filter == 'All') return true;
          final data = doc.data() as Map<String, dynamic>;
          final type = (data['event_type'] ?? '').toString();
          return type.toLowerCase() == filter.toLowerCase();
        }).toList();

        if (docs.isEmpty) {
          return const Text(
            'No events enrolled yet for this filter.',
            style: TextStyle(color: Colors.teal),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = data['event_type'] ?? '';
            return ListTile(
              dense: true,
              leading: const Icon(Icons.event, color: Colors.teal),
              title: Text(
                data['eventName'] ?? 'Event',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(type.toString()),
            );
          }).toList(),
        );
      },
    );
  }
}