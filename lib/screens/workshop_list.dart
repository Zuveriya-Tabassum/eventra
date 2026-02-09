import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'workshop_registration_form.dart';

class WorkshopListPage extends StatefulWidget {
  const WorkshopListPage({super.key});

  @override
  State<WorkshopListPage> createState() => _WorkshopListPageState();
}

class _WorkshopListPageState extends State<WorkshopListPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Workshop> staticWorkshops = [];
  String? _role;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRole();

    // Static sample workshops (cannot be edited/deleted)
    staticWorkshops = [
      Workshop(
        id: 'static_1',
        logoPath: 'assets/images/logo1.jpeg',
        name: 'Campus Code Clash',
        description:
        'A thrilling 24-hour coding marathon tailored for campus coders.\nTest your logic, speed, and teamwork in real-world programming scenarios.',
        venue: 'Main Auditorium',
        deadline:
        DateTime.now().add(const Duration(days: 2, hours: 5, minutes: 30)),
        organizer: 'Dept. of CSE - Tech Club',
        prerequisites: 'Open for all CSE/IT students. Basic C/C++ required.',
        createdBy: 'system',
        fee: 200,
        qrUrl: '',
        offlineContactPhone: '9876543210',
        offlineContactEmail: 'organizer@clg.edu',
      ),
      Workshop(
        id: 'static_2',
        logoPath: 'assets/images/logo2.jpeg',
        name: 'AI for Social Good',
        description:
        'Develop AI-driven ideas to solve local social problems.\nWork in teams to turn ethical AI ideas into impactful prototypes.',
        venue: 'Lab Block 2 – Seminar Hall',
        deadline: DateTime.now().add(const Duration(hours: 10)),
        organizer: 'AI Research Club',
        prerequisites: 'AI/ML knowledge, team of 2-3 students.',
        createdBy: 'system',
        fee: 200,
        qrUrl: '',
        offlineContactPhone: '9876543210',
        offlineContactEmail: 'organizer@clg.edu',
      ),
      Workshop(
        id: 'static_3',
        logoPath: 'assets/images/logo1.jpeg',
        name: 'Web Dev Sprint',
        description:
        'Build responsive websites in 12 hours!\nShow off your front-end skills and creative problem-solving.',
        venue: 'Innovation Hub - Room 310',
        deadline: DateTime.now().subtract(const Duration(hours: 5)),
        organizer: 'Web Club + IEEE Student Chapter',
        prerequisites: 'HTML, CSS, JS. Bring your laptop.',
        createdBy: 'system',
        fee: 200,
        qrUrl: '',
        offlineContactPhone: '9876543210',
        offlineContactEmail: 'organizer@clg.edu',
      ),
      Workshop(
        id: 'static_4',
        logoPath: 'assets/images/logo3.jpeg',
        name: 'Flutter Bootcamp',
        description:
        'Intensive mobile app development workshop using Flutter.\nLearn to build cross-platform apps from scratch to deployment.',
        venue: 'Computer Lab A',
        deadline: DateTime.now().add(const Duration(days: 3, hours: 2)),
        organizer: 'Google Developer Student Club',
        prerequisites:
        'Basic programming knowledge, Android Studio installed.',
        createdBy: 'system',
        fee: 200,
        qrUrl: '',
        offlineContactPhone: '9876543210',
        offlineContactEmail: 'organizer@clg.edu',
      ),
      Workshop(
        id: 'static_5',
        logoPath: 'assets/images/logo2.jpeg',
        name: 'Data Science Workshop',
        description:
        'Explore data analysis, visualization, and machine learning.\nHands-on experience with Python, pandas, and scikit-learn.',
        venue: 'Analytics Lab - Block C',
        deadline: DateTime.now().add(const Duration(days: 1, hours: 14)),
        organizer: 'Data Science Society',
        prerequisites: 'Python basics, statistics knowledge preferred.',
        createdBy: 'system',
        fee: 200,
        qrUrl: '',
        offlineContactPhone: '9876543210',
        offlineContactEmail: 'organizer@clg.edu',
      ),
      Workshop(
        id: 'static_6',
        logoPath: 'assets/images/logo5.jpeg',
        name: 'Cybersecurity Challenge',
        description:
        'Learn ethical hacking and cybersecurity fundamentals.\nParticipate in capture-the-flag challenges and security assessments.',
        venue: 'Security Lab - IT Wing',
        deadline: DateTime.now().add(const Duration(days: 4, hours: 8)),
        organizer: 'CyberSec Club',
        prerequisites: 'Networking basics, Linux familiarity helpful.',
        createdBy: 'system',
        fee: 200,
        qrUrl: '',
        offlineContactPhone: '9876543210',
        offlineContactEmail: 'organizer@clg.edu',
      ),
      Workshop(
        id: 'static_7',
        logoPath: 'assets/images/logo6.jpeg',
        name: 'Blockchain Fundamentals',
        description:
        'Understanding blockchain technology and cryptocurrency.\nBuild your first smart contract and explore DeFi concepts.',
        venue: 'Seminar Hall 1',
        deadline: DateTime.now().add(const Duration(days: 6)),
        organizer: 'Blockchain Innovation Club',
        prerequisites: 'Programming experience, crypto wallet setup.',
        createdBy: 'system',
        fee: 200,
        qrUrl: '',
        offlineContactPhone: '9876543210',
        offlineContactEmail: 'organizer@clg.edu',
      ),
    ];
  }

  Future<void> _loadRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    setState(() {
      _role = snap.data()?['role'] as String? ?? 'Participant';
    });
  }

  bool get _isAdmin => _role == 'Admin';
  bool get _isClubHead => _role == 'Club Head';

  List<Workshop> _filterByTab(List<Workshop> all, int tabIndex) {
    final now = DateTime.now();
    if (tabIndex == 0) {
      return all
          .where((w) => w.deadline.isAfter(now.add(const Duration(hours: 24))))
          .toList();
    } else if (tabIndex == 1) {
      return all.where((w) {
        final diff = w.deadline.difference(now);
        return diff.inHours <= 24 && !diff.isNegative;
      }).toList();
    } else {
      return all.where((w) => w.deadline.isBefore(now)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
                  (route) => false,
            );
          },
        ),
        title: const Text('Workshops'),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: user == null
          ? const Center(
          child: Text(
            'Please login to view workshops',
            style: TextStyle(color: Colors.grey),
          ))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workshops')
            .orderBy('deadline')
            .snapshots(),
        builder: (context, snap) {
          final dynamicWorkshops = <Workshop>[];
          if (snap.hasData) {
            for (final d in snap.data!.docs) {
              final data = d.data() as Map<String, dynamic>;
              dynamicWorkshops.add(Workshop(
                id: d.id,
                logoPath: data['logoPath'] ?? 'assets/images/logo1.jpeg',
                name: data['name'] ?? '',
                description: data['description'] ?? '',
                venue: data['venue'] ?? '',
                deadline:
                (data['deadline'] as Timestamp).toDate(),
                organizer: data['organizer'] ?? '',
                prerequisites: data['prerequisites'] ?? '',
                createdBy: data['createdBy'] ?? '',
                fee: (data['fee'] ?? 0) as int,
                qrUrl: data['qrUrl'] ?? '',
                offlineContactPhone: data['offlineContactPhone'] ?? '',
                offlineContactEmail: data['offlineContactEmail'] ?? '',
              ));
            }
          }

          final all = [...staticWorkshops, ...dynamicWorkshops];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildWorkshopList(
                  _filterByTab(all, 0), 0, user.uid),
              _buildWorkshopList(
                  _filterByTab(all, 1), 1, user.uid),
              _buildWorkshopList(
                  _filterByTab(all, 2), 2, user.uid),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWorkshopList(List<Workshop> list, int tabIndex, String uid) {
    final showAddCard =
        (tabIndex == 0 || tabIndex == 1) && (_isAdmin || _isClubHead);

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        if (showAddCard)
          _AddWorkshopCard(
            onAdded: () => setState(() {}),
          ),
        if (list.isEmpty)
          const SizedBox(
            height: 200,
            child: Center(child: Text('No events found.')),
          )
        else
          ...list.map(
                (w) => WorkshopCard(
              workshop: w,
              currentUserId: uid,
              role: _role ?? 'Participant',
            ),
          ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '* All events follow college participation rules. Bring your ID card.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class Workshop {
  final String id;
  final String logoPath;
  final String name;
  final String description;
  final String venue;
  final DateTime deadline;
  final String organizer;
  final String prerequisites;
  final String createdBy;
  final int fee;
  final String qrUrl;
  final String offlineContactPhone;
  final String offlineContactEmail;

  Workshop({
    required this.id,
    required this.logoPath,
    required this.name,
    required this.description,
    required this.venue,
    required this.deadline,
    required this.organizer,
    required this.prerequisites,
    required this.createdBy,
    required this.fee,
    required this.qrUrl,
    required this.offlineContactPhone,
    required this.offlineContactEmail,
  });
}

class WorkshopCard extends StatefulWidget {
  final Workshop workshop;
  final String currentUserId;
  final String role;

  const WorkshopCard({
    super.key,
    required this.workshop,
    required this.currentUserId,
    required this.role,
  });

  @override
  State<WorkshopCard> createState() => _WorkshopCardState();
}

class _WorkshopCardState extends State<WorkshopCard>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  bool get _isAdmin => widget.role == 'Admin';
  bool get _isClubHead => widget.role == 'Club Head';

  bool get _canEditOrDelete {
    if (_isAdmin) return true;
    if (_isClubHead && widget.workshop.createdBy == widget.currentUserId) {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => isExpanded = !isExpanded);
  }

  Future<void> _deleteWorkshop() async {
    if (!_canEditOrDelete) return;
    final isStatic = widget.workshop.id.startsWith('static_');
    if (isStatic) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete workshop?'),
        content:
        const Text('This will permanently remove this workshop entry.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ??
        false;
    if (!ok) return;

    await FirebaseFirestore.instance
        .collection('workshops')
        .doc(widget.workshop.id)
        .delete();
  }

  Future<void> _editWorkshop() async {
    if (!_canEditOrDelete) return;
    final w = widget.workshop;

    final nameC = TextEditingController(text: w.name);
    final descC = TextEditingController(text: w.description);
    final venueC = TextEditingController(text: w.venue);
    final orgC = TextEditingController(text: w.organizer);
    final preC = TextEditingController(text: w.prerequisites);
    final feeC = TextEditingController(text: w.fee.toString());
    final phoneC = TextEditingController(text: w.offlineContactPhone);
    final emailC = TextEditingController(text: w.offlineContactEmail);
    DateTime selectedDeadline = w.deadline;
    String qrUrl = w.qrUrl;
    Uint8List? qrBytes;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Edit Workshop'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    controller: nameC),
                TextField(
                  decoration:
                  const InputDecoration(labelText: 'Description'),
                  controller: descC,
                  maxLines: 3,
                ),
                TextField(
                    decoration: const InputDecoration(labelText: 'Venue'),
                    controller: venueC),
                TextField(
                    decoration:
                    const InputDecoration(labelText: 'Organized By'),
                    controller: orgC),
                TextField(
                    decoration:
                    const InputDecoration(labelText: 'Prerequisites'),
                    controller: preC),
                TextField(
                  decoration:
                  const InputDecoration(labelText: 'Enrollment Fee (₹)'),
                  keyboardType: TextInputType.number,
                  controller: feeC,
                ),
                TextField(
                  decoration:
                  const InputDecoration(labelText: 'Offline Contact Phone'),
                  keyboardType: TextInputType.phone,
                  controller: phoneC,
                ),
                TextField(
                  decoration:
                  const InputDecoration(labelText: 'Offline Contact Email'),
                  keyboardType: TextInputType.emailAddress,
                  controller: emailC,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Deadline: '),
                    Expanded(
                      child: Text(
                        DateFormat('MMM dd, yyyy – hh:mm a')
                            .format(selectedDeadline),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: dialogCtx,
                          initialDate: selectedDeadline,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 2)),
                        );
                        if (date == null) return;
                        final time = await showTimePicker(
                          context: dialogCtx,
                          initialTime:
                          TimeOfDay.fromDateTime(selectedDeadline),
                        );
                        if (time == null) return;
                        selectedDeadline = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                        setDialogState(() {});
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payment QR Code:'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result =
                              await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                allowMultiple: false,
                                withData: true,
                              );
                              if (result != null &&
                                  result.files.single.bytes != null) {
                                qrBytes = result.files.single.bytes;
                                setDialogState(() {});
                              }
                            },
                            icon: const Icon(Icons.qr_code_2),
                            label: const Text('Upload QR'),
                          ),
                          const SizedBox(width: 8),
                          if (qrBytes != null)
                            const Icon(Icons.check_circle,
                                color: Colors.green),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (qrUrl.isNotEmpty && qrBytes == null)
                        SizedBox(
                          height: 80,
                          child: Image.network(
                            qrUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final parsedFee = int.tryParse(feeC.text.trim()) ?? 0;
                String newQrUrl = qrUrl;

                try {
                  if (qrBytes != null) {
                    final ref = FirebaseStorage.instance
                        .ref()
                        .child('workshop_qr/${w.id}.png');
                    await ref.putData(
                      qrBytes!,
                      SettableMetadata(contentType: 'image/png'),
                    );
                    newQrUrl = await ref.getDownloadURL();
                  }

                  await FirebaseFirestore.instance
                      .collection('workshops')
                      .doc(w.id)
                      .update({
                    'name': nameC.text.trim(),
                    'description': descC.text.trim(),
                    'venue': venueC.text.trim(),
                    'organizer': orgC.text.trim(),
                    'prerequisites': preC.text.trim(),
                    'deadline': selectedDeadline,
                    'fee': parsedFee,
                    'qrUrl': newQrUrl,
                    'offlineContactPhone': phoneC.text.trim(),
                    'offlineContactEmail': emailC.text.trim(),
                  });

                  if (Navigator.of(dialogCtx).canPop()) {
                    Navigator.pop(dialogCtx);
                  }
                } catch (e) {
                  // simple debug – you can replace with SnackBar
                  // ignore: avoid_print
                  print('Error saving workshop: $e');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Card(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 48, color: Colors.grey),
              const Text('Please login to view workshops'),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }
    return FadeTransition(
      opacity: _fadeIn,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isExpanded ? Colors.teal.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.10),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('enrollments')
              .doc(widget.workshop.name)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() as Map<String, dynamic>?;
            final status = data?['status'] ?? '';
            return AnimatedPadding(
              duration: const Duration(milliseconds: 400),
              padding: EdgeInsets.all(isExpanded ? 26 : 14),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: isExpanded
                        ? Icon(Icons.emoji_events,
                        size: 40,
                        color: Colors.teal.shade700,
                        key: const ValueKey('exp'))
                        : const Icon(Icons.flash_on,
                        size: 36,
                        color: Colors.teal,
                        key: ValueKey('min')),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: isExpanded ? 60 : 40,
                        height: isExpanded ? 60 : 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.teal, Colors.tealAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.workshop.name.isNotEmpty
                              ? widget.workshop.name.substring(0, 1)
                              : '?',
                          style: TextStyle(
                            fontSize: isExpanded ? 24 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.workshop.name,
                              style: TextStyle(
                                  fontSize: isExpanded ? 18 : 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy – hh:mm a')
                                  .format(widget.workshop.deadline),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                            CountdownTimer(
                                deadline: widget.workshop.deadline),
                            if (widget.workshop.fee > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Fee: ₹${widget.workshop.fee}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_canEditOrDelete && isExpanded)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit,
                                  size: 20, color: Colors.blueGrey),
                              onPressed: _editWorkshop,
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete,
                                  size: 20, color: Colors.redAccent),
                              onPressed: _deleteWorkshop,
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(widget.workshop.description),
                  const SizedBox(height: 4),
                  Text('📍 ${widget.workshop.venue}',
                      style: const TextStyle(color: Colors.grey)),
                  if (isExpanded && widget.workshop.qrUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        children: [
                          const Text(
                            'Scan to Pay',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 150,
                            child: Image.network(
                              widget.workshop.qrUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!isExpanded)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                            backgroundColor: Colors.teal),
                        onPressed: _toggleExpanded,
                        child: const Text(
                          'View Details',
                          style: TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ),
                    ),
                  if (isExpanded) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🏢 Organized By: ${widget.workshop.organizer}'),
                          const SizedBox(height: 5),
                          Text(
                              '✅ Prerequisites: ${widget.workshop.prerequisites}'),
                        ],
                      ),
                    ),
                    if (widget.workshop.deadline.isAfter(DateTime.now()))
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed:
                          (status == 'approved' || status == 'pending')
                              ? null
                              : () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RegistrationFormPage(
                                      eventName: widget.workshop.name,
                                      venue: widget.workshop.venue,
                                      deadline:
                                      widget.workshop.deadline,
                                      studentName: '',
                                      rollNumber: '',
                                      fee: widget.workshop.fee,
                                      qrUrl: widget.workshop.qrUrl,
                                      offlineContactPhone:
                                      widget.workshop
                                          .offlineContactPhone,
                                      offlineContactEmail:
                                      widget.workshop
                                          .offlineContactEmail,
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: status == 'approved'
                                ? Colors.grey
                                : status == 'pending'
                                ? Colors.orange
                                : Colors.teal,
                          ),
                          child: Text(
                            status == 'approved'
                                ? 'Enrolled'
                                : status == 'pending'
                                ? 'Pending'
                                : 'Enroll',
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: _toggleExpanded,
                        icon:
                        const Icon(Icons.keyboard_arrow_up_rounded),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AddWorkshopCard extends StatelessWidget {
  final VoidCallback onAdded;
  const _AddWorkshopCard({required this.onAdded});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openAddDialog(context),
        child: Container(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal,
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Add New Workshop',
                  style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAddDialog(BuildContext context) async {
    final nameC = TextEditingController();
    final descC = TextEditingController();
    final venueC = TextEditingController();
    final orgC = TextEditingController();
    final preC = TextEditingController();
    final feeC = TextEditingController(text: '200');
    final phoneC = TextEditingController(text: '9876543210');
    final emailC = TextEditingController(text: 'organizer@clg.edu');
    DateTime selectedDeadline = DateTime.now().add(const Duration(hours: 1));
    Uint8List? qrBytes;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('New Workshop'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    controller: nameC),
                TextField(
                  decoration:
                  const InputDecoration(labelText: 'Description'),
                  controller: descC,
                  maxLines: 3,
                ),
                TextField(
                    decoration: const InputDecoration(labelText: 'Venue'),
                    controller: venueC),
                TextField(
                    decoration:
                    const InputDecoration(labelText: 'Organized By'),
                    controller: orgC),
                TextField(
                    decoration:
                    const InputDecoration(labelText: 'Prerequisites'),
                    controller: preC),
                TextField(
                  decoration:
                  const InputDecoration(labelText: 'Enrollment Fee (₹)'),
                  keyboardType: TextInputType.number,
                  controller: feeC,
                ),
                TextField(
                  decoration:
                  const InputDecoration(labelText: 'Offline Contact Phone'),
                  keyboardType: TextInputType.phone,
                  controller: phoneC,
                ),
                TextField(
                  decoration:
                  const InputDecoration(labelText: 'Offline Contact Email'),
                  keyboardType: TextInputType.emailAddress,
                  controller: emailC,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Deadline: '),
                    Expanded(
                      child: Text(
                        DateFormat('MMM dd, yyyy – hh:mm a')
                            .format(selectedDeadline),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: dialogCtx,
                          initialDate: selectedDeadline,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 1)),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 2)),
                        );
                        if (date == null) return;
                        final time = await showTimePicker(
                          context: dialogCtx,
                          initialTime:
                          TimeOfDay.fromDateTime(selectedDeadline),
                        );
                        if (time == null) return;
                        selectedDeadline = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                        setDialogState(() {});
                      },
                      child: const Text('Pick'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payment QR Code:'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result =
                              await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                allowMultiple: false,
                                withData: true,
                              );
                              if (result != null &&
                                  result.files.single.bytes != null) {
                                qrBytes = result.files.single.bytes;
                                setDialogState(() {});
                              }
                            },
                            icon: const Icon(Icons.qr_code_2),
                            label: const Text('Upload QR'),
                          ),
                          const SizedBox(width: 8),
                          if (qrBytes != null)
                            const Icon(Icons.check_circle,
                                color: Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                final fee = int.tryParse(feeC.text.trim()) ?? 0;

                final docRef =
                FirebaseFirestore.instance.collection('workshops').doc();
                String qrUrl = '';

                try {
                  if (qrBytes != null) {
                    final ref = FirebaseStorage.instance
                        .ref()
                        .child('workshop_qr/${docRef.id}.png');
                    await ref.putData(
                      qrBytes!,
                      SettableMetadata(contentType: 'image/png'),
                    );
                    qrUrl = await ref.getDownloadURL();
                  }

                  await docRef.set({
                    'name': nameC.text.trim(),
                    'description': descC.text.trim(),
                    'venue': venueC.text.trim(),
                    'organizer': orgC.text.trim(),
                    'prerequisites': preC.text.trim(),
                    'deadline': selectedDeadline,
                    'logoPath': 'assets/images/logo1.jpeg',
                    'createdBy': user.uid,
                    'fee': fee,
                    'qrUrl': qrUrl,
                    'offlineContactPhone': phoneC.text.trim(),
                    'offlineContactEmail': emailC.text.trim(),
                  });

                  onAdded();
                  if (Navigator.of(dialogCtx).canPop()) {
                    Navigator.pop(dialogCtx);
                  }
                } catch (e) {
                  // ignore: avoid_print
                  print('Error creating workshop: $e');
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class CountdownTimer extends StatefulWidget {
  final DateTime deadline;
  const CountdownTimer({super.key, required this.deadline});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _timeLeft = widget.deadline.difference(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft.isNegative) {
      return const Text(
        "Expired",
        style: TextStyle(color: Colors.red),
      );
    }
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;
    return Text(
      "⏳ ${days}d ${hours}h ${minutes}m ${seconds}s",
      style: const TextStyle(fontSize: 12),
    );
  }
}
