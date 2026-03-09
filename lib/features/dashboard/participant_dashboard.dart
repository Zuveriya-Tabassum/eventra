// lib/features/dashboard/participant_dashboard.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/presentation/app_drawer.dart';

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
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || user == null) return;

    String? newImageUrl = _profileImageUrl;

    if (_imageFile != null) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user!.uid}.jpg');
        await ref.putFile(_imageFile!);
        newImageUrl = await ref.getDownloadURL();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
        }
      }
    }

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'name': _nameController.text,
      'phone': _phoneController.text,
      'bio': _bioController.text,
      'department': _departmentController.text,
      'year': _yearController.text,
      if (newImageUrl != null) 'profileImage': newImageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _isEditing = false;
      if (newImageUrl != null) _profileImageUrl = newImageUrl;
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to see your dashboard.")),
      );
    }

    final userId = user!.uid;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      drawer: const AppDrawer(currentIndex: 2),
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.save : Icons.edit,
              color: Colors.white,
            ),
            onPressed: _isEditing
                ? _saveProfile
                : () => setState(() => _isEditing = true),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .snapshots(),
          builder: (context, snapshot) {
            int streak = 0;
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              streak = data['streak'] ?? 0;
              _profileImageUrl = data['profileImage'];
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: _buildProfileCard(streak, userId, true),
                        ),
                        const SizedBox(width: 16),
                        Expanded(flex: 6, child: _buildAnalyticsCard(userId)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildProfileCard(streak, userId, false),
                        const SizedBox(height: 16),
                        _buildAnalyticsCard(userId),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileCard(int streak, String userId, bool wide) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAvatar(),
              const SizedBox(height: 20),
              _isEditing
                  ? TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : Text(
                      _nameController.text.isEmpty
                          ? 'Your Name'
                          : _nameController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              Text(
                user?.email ?? '',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statBadge(
                    Icons.local_fire_department,
                    streak.toString(),
                    Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _statBadge(Icons.event_available, '12', Colors.blue),
                ],
              ),
              const SizedBox(height: 24),
              _detailRow(Icons.phone, 'Phone', _phoneController),
              _detailRow(Icons.school, 'Dept', _departmentController),
              _detailRow(Icons.calendar_month, 'Year', _yearController),
              _detailRow(Icons.description, 'Bio', _bioController, maxLines: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.1),
          backgroundImage: _imageFile != null
              ? FileImage(_imageFile!)
              : (_profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : null)
                    as ImageProvider?,
          child: (_imageFile == null && _profileImageUrl == null)
              ? Icon(
                  Icons.person,
                  size: 60,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
        ),
        if (_isEditing)
          Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              radius: 18,
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
                onPressed: _pickImage,
              ),
            ),
          ),
      ],
    );
  }

  Widget _statBadge(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _isEditing
          ? TextFormField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon, size: 20),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        controller.text.isEmpty
                            ? 'Not provided'
                            : controller.text,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAnalyticsCard(String userId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participation Analytics',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(height: 200, child: _EnrollmentPieChart(userId: userId)),
            const SizedBox(height: 32),
            Text(
              'Activity (Last 7 Days)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: _PerformanceLineChart(userId: userId)),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildEnrolledSection(userId),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledSection(String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enrolled Events',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            DropdownButton<String>(
              value: _enrolledFilter,
              items: ['All', 'Hackathon', 'Workshop'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _enrolledFilter = v!),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _EnrolledEventsList(userId: userId, filter: _enrolledFilter),
      ],
    );
  }
}

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
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        int hack = 0, work = 0, quiz = 0;
        for (var doc in snap.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          hack += (data['hackathon'] ?? 0) as int;
          work += (data['workshop'] ?? 0) as int;
          quiz += (data['quiz'] ?? 0) as int;
        }
        if (hack == 0 && work == 0 && quiz == 0)
          return const Center(
            child: Text('No data yet', style: TextStyle(color: Colors.grey)),
          );

        return PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: 40,
            sections: [
              PieChartSectionData(
                value: hack.toDouble(),
                color: Colors.deepPurple,
                title: 'Hacks',
                radius: 50,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              PieChartSectionData(
                value: work.toDouble(),
                color: Colors.orange,
                title: 'Work',
                radius: 50,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              PieChartSectionData(
                value: quiz.toDouble(),
                color: Colors.blue,
                title: 'Quiz',
                radius: 50,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty)
          return const Center(
            child: Text(
              'No recent activity',
              style: TextStyle(color: Colors.grey),
            ),
          );

        List<FlSpot> spots = [];
        for (int i = 0; i < docs.length; i++) {
          final d = docs[i].data() as Map<String, dynamic>;
          final score =
              (d['hackathon'] ?? 0) * 2 +
              (d['workshop'] ?? 0) +
              (d['quiz'] ?? 0);
          spots.add(FlSpot(i.toDouble(), score.toDouble()));
        }

        return LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (v, m) => Text(
                    v.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, m) {
                    int i = v.toInt();
                    if (i >= 0 && i < docs.length)
                      return Text(
                        docs[i]['date'].toString().substring(5),
                        style: const TextStyle(fontSize: 10),
                      );
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
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Theme.of(context).colorScheme.primary,
                barWidth: 4,
                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EnrolledEventsList extends StatelessWidget {
  final String userId;
  final String filter;
  const _EnrolledEventsList({required this.userId, required this.filter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('enrollments')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs.where((doc) {
          if (filter == 'All') return true;
          return (doc.data() as Map<String, dynamic>)['eventType']
                  ?.toString()
                  .toLowerCase() ==
              filter.toLowerCase();
        }).toList();

        if (docs.isEmpty)
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No events found',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.event,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(
                d['eventName'] ?? 'Event',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(d['eventType']?.toString().toUpperCase() ?? ''),
              trailing: const Icon(Icons.chevron_right, size: 16),
            );
          },
        );
      },
    );
  }
}
