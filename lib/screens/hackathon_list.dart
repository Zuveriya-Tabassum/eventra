import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'registration_form.dart';

class HackathonListPage extends StatefulWidget {
  const HackathonListPage({super.key});

  @override
  State<HackathonListPage> createState() => _HackathonListPageState();
}

class _HackathonListPageState extends State<HackathonListPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Hackathon> staticHackathons = [];
  String? _role;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRole();

    staticHackathons = [
      Hackathon(
        id: 'static_h1',
        logoPath: 'assets/hack1.png',
        name: 'Campus Code Clash',
        description:
        'A 24-hour coding challenge for campus students.\nTest your logic, speed, and teamwork in real-world programming scenarios.',
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
      Hackathon(
        id: 'static_h2',
        logoPath: 'assets/hack2.png',
        name: 'AI for Social Good',
        description:
        'Develop AI-driven ideas to solve local social problems.\nWork in teams to turn ethical AI ideas into impactful prototypes.',
        venue: 'Lab Block 2 – Seminar Hall',
        deadline: DateTime.now().add(const Duration(days: 5, hours: 2)),
        organizer: 'AI Research Club',
        prerequisites: 'AI/ML knowledge, team of 2-3 students.',
        createdBy: 'system',
        fee: 200,
        qrUrl: '',
        offlineContactPhone: '9876543210',
        offlineContactEmail: 'organizer@clg.edu',
      ),
      Hackathon(
        id: 'static_h3',
        logoPath: 'assets/hack3.png',
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
      Hackathon(
        id: 'static_h4',
        logoPath: 'assets/hack4.png',
        name: 'Blockchain Challenge',
        description:
        'Build decentralized applications and smart contracts.\nExplore the future of blockchain technology.',
        venue: 'Tech Lab - Block A',
        deadline: DateTime.now().add(const Duration(days: 3, hours: 8)),
        organizer: 'Blockchain Club',
        prerequisites: 'Basic programming knowledge, crypto wallet setup.',
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

  List<Hackathon> _filterByTab(List<Hackathon> all, int tabIndex) {
    final now = DateTime.now();
    if (tabIndex == 0) {
      return all
          .where((h) => h.deadline.isAfter(now.add(const Duration(hours: 24))))
          .toList();
    } else if (tabIndex == 1) {
      return all.where((h) {
        final diff = h.deadline.difference(now);
        return diff.inHours <= 24 && !diff.isNegative;
      }).toList();
    } else {
      return all.where((h) => h.deadline.isBefore(now)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        fontFamily: 'Poppins',
        brightness: Brightness.light,
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFE0F2F1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          title: const Text('Hackathons'),
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
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('hackathons')
              .orderBy('deadline')
              .snapshots(),
          builder: (context, snap) {
            final dynamicHackathons = <Hackathon>[];
            if (snap.hasData) {
              for (final d in snap.data!.docs) {
                final data = d.data() as Map<String, dynamic>;
                dynamicHackathons.add(
                  Hackathon(
                    id: d.id,
                    logoPath: data['logoPath'] ?? 'assets/hack1.png',
                    name: data['name'] ?? '',
                    description: data['description'] ?? '',
                    venue: data['venue'] ?? '',
                    deadline: (data['deadline'] as Timestamp).toDate(),
                    organizer: data['organizer'] ?? '',
                    prerequisites: data['prerequisites'] ?? '',
                    createdBy: data['createdBy'] ?? '',
                    fee: (data['fee'] ?? 0) as int,
                    qrUrl: data['qrUrl'] ?? '',
                    offlineContactPhone: data['offlineContactPhone'] ?? '',
                    offlineContactEmail: data['offlineContactEmail'] ?? '',
                  ),
                );
              }
            }

            final all = [...staticHackathons, ...dynamicHackathons];

            return TabBarView(
              controller: _tabController,
              children: [
                _buildHackathonList(_filterByTab(all, 0), 0),
                _buildHackathonList(_filterByTab(all, 1), 1),
                _buildHackathonList(_filterByTab(all, 2), 2),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHackathonList(List<Hackathon> list, int tabIndex) {
    final showAddCard =
        (tabIndex == 0 || tabIndex == 1) && (_isAdmin || _isClubHead);

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        if (showAddCard)
          _AddHackathonCard(
            onAdded: () => setState(() {}),
          ),
        if (list.isEmpty)
          const SizedBox(
            height: 200,
            child: Center(child: Text('No events found.')),
          )
        else
          ...list.map(
                (h) => HackathonCard(
              hackathon: h,
              currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
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

class Hackathon {
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

  Hackathon({
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

class HackathonCard extends StatefulWidget {
  final Hackathon hackathon;
  final String currentUserId;
  final String role;

  const HackathonCard({
    super.key,
    required this.hackathon,
    required this.currentUserId,
    required this.role,
  });

  @override
  State<HackathonCard> createState() => _HackathonCardState();
}

class _HackathonCardState extends State<HackathonCard>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  bool get _isAdmin => widget.role == 'Admin';
  bool get _isClubHead => widget.role == 'Club Head';

  bool get _canEditOrDelete {
    if (_isAdmin) return true;
    if (_isClubHead && widget.hackathon.createdBy == widget.currentUserId) {
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

  Future<void> _deleteHackathon() async {
    if (!_canEditOrDelete) return;
    final isStatic = widget.hackathon.id.startsWith('static_');
    if (isStatic) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete hackathon?'),
        content: const Text(
          'This will permanently remove this hackathon entry.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ??
        false;
    if (!ok) return;

    await FirebaseFirestore.instance
        .collection('hackathons')
        .doc(widget.hackathon.id)
        .delete();
  }

  Future<void> _editHackathon() async {
    if (!_canEditOrDelete) return;
    final h = widget.hackathon;

    final nameC = TextEditingController(text: h.name);
    final descC = TextEditingController(text: h.description);
    final venueC = TextEditingController(text: h.venue);
    final orgC = TextEditingController(text: h.organizer);
    final preC = TextEditingController(text: h.prerequisites);
    final feeC = TextEditingController(text: h.fee.toString());
    final phoneC = TextEditingController(text: h.offlineContactPhone);
    final emailC = TextEditingController(text: h.offlineContactEmail);
    DateTime selectedDeadline = h.deadline;
    String qrUrl = h.qrUrl;
    Uint8List? qrBytes;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Edit Hackathon'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  controller: nameC,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  controller: descC,
                  maxLines: 3,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Venue'),
                  controller: venueC,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Organized By'),
                  controller: orgC,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Prerequisites'),
                  controller: preC,
                ),
                TextField(
                  decoration:
                  const InputDecoration(labelText: 'Enrollment Fee (₹)'),
                  keyboardType: TextInputType.number,
                  controller: feeC,
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Offline Contact Phone',
                  ),
                  keyboardType: TextInputType.phone,
                  controller: phoneC,
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Offline Contact Email',
                  ),
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
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
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
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final parsedFee = int.tryParse(feeC.text.trim()) ?? 0;
                String newQrUrl = qrUrl;
                try {
                  if (qrBytes != null) {
                    final ref = FirebaseStorage.instance
                        .ref()
                        .child('hackathon_qr/${h.id}.png');
                    await ref.putData(
                      qrBytes!,
                      SettableMetadata(contentType: 'image/png'),
                    );
                    newQrUrl = await ref.getDownloadURL();
                  }

                  await FirebaseFirestore.instance
                      .collection('hackathons')
                      .doc(h.id)
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
                  // ignore: avoid_print
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: no status filter, show all enrolled docs
  Stream<QuerySnapshot> _enrollmentStream() {
    return FirebaseFirestore.instance
        .collection('hackathons')
        .doc(widget.hackathon.id)
        .collection('enrollments')
        .snapshots();
  }

  void _showParticipantsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StreamBuilder<QuerySnapshot>(
          stream: _enrollmentStream(),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: Text('No participants enrolled yet.'),
                ),
              );
            }
            return SizedBox(
              height: 350,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Enrolled Participants',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (ctx, i) {
                        final data =
                        docs[i].data() as Map<String, dynamic>;
                        final name = data['name'] ?? '';
                        final roll = data['rollNo'] ?? '';
                        final branch = data['branch'] ?? '';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.shade100,
                            child: Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.teal),
                            ),
                          ),
                          title: Text(name),
                          subtitle: Text(
                            roll.isNotEmpty
                                ? 'Roll: $roll'
                                : branch.toString(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
              const Text('Please login to view hackathons'),
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
              .doc(widget.hackathon.name)
              .snapshots(),
          builder: (context, snapshot) {
            final data =
            snapshot.data?.data() as Map<String, dynamic>?;
            final status = data?['status'] ?? '';

            return AnimatedPadding(
              duration: const Duration(milliseconds: 400),
              padding: EdgeInsets.all(isExpanded ? 26 : 14),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: isExpanded
                        ? Icon(
                      Icons.code,
                      size: 40,
                      color: Colors.teal.shade700,
                      key: const ValueKey('exp'),
                    )
                        : const Icon(
                      Icons.bolt,
                      size: 36,
                      color: Colors.teal,
                      key: ValueKey('min'),
                    ),
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
                          widget.hackathon.name.substring(0, 1).toUpperCase(),
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
                              widget.hackathon.name,
                              style: TextStyle(
                                fontSize: isExpanded ? 18 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy – hh:mm a')
                                  .format(widget.hackathon.deadline),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            CountdownTimer(
                              deadline: widget.hackathon.deadline,
                            ),
                            if (widget.hackathon.fee > 0)
                              Padding(
                                padding:
                                const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Fee: ₹${widget.hackathon.fee}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                            StreamBuilder<QuerySnapshot>(
                              stream: _enrollmentStream(),
                              builder: (context, snap) {
                                final count = snap.hasData
                                    ? snap.data!.docs.length
                                    : 0;
                                final text =
                                    '$count participant${count == 1 ? '' : 's'} enrolled';
                                return Padding(
                                  padding:
                                  const EdgeInsets.only(top: 4.0),
                                  child: InkWell(
                                    onTap: count == 0
                                        ? null
                                        : _showParticipantsSheet,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.people,
                                          size: 16,
                                          color: Colors.teal,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          text,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.teal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
                              icon: const Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.blueGrey,
                              ),
                              onPressed: _editHackathon,
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.redAccent,
                              ),
                              onPressed: _deleteHackathon,
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(widget.hackathon.description),
                  const SizedBox(height: 4),
                  Text(
                    '📍 ${widget.hackathon.venue}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (isExpanded && widget.hackathon.qrUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        children: [
                          const Text(
                            'Scan to Pay',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 150,
                            child: Image.network(
                              widget.hackathon.qrUrl,
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
                          backgroundColor: Colors.teal,
                        ),
                        onPressed: _toggleExpanded,
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
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
                          Text(
                            '🏢 Organized By: ${widget.hackathon.organizer}',
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '✅ Prerequisites: ${widget.hackathon.prerequisites}',
                          ),
                        ],
                      ),
                    ),
                    if (widget.hackathon.deadline.isAfter(DateTime.now()))
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: (status == 'approved' ||
                              status == 'pending')
                              ? null
                              : () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RegistrationFormPage(
                                      eventName:
                                      widget.hackathon.name,
                                      venue: widget.hackathon.venue,
                                      deadline:
                                      widget.hackathon.deadline,
                                      fee: widget.hackathon.fee,
                                      qrUrl: widget.hackathon.qrUrl,
                                      offlineContactPhone: widget
                                          .hackathon
                                          .offlineContactPhone,
                                      offlineContactEmail: widget
                                          .hackathon
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
                        icon: const Icon(
                          Icons.keyboard_arrow_up_rounded,
                        ),
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

class _AddHackathonCard extends StatelessWidget {
  final VoidCallback onAdded;
  const _AddHackathonCard({required this.onAdded});

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
                  'Add New Hackathon',
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
          title: const Text('New Hackathon'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  controller: nameC,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  controller: descC,
                  maxLines: 3,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Venue'),
                  controller: venueC,
                ),
                TextField(
                  decoration:
                  const InputDecoration(labelText: 'Organized By'),
                  controller: orgC,
                ),
                TextField(
                  decoration:
                  const InputDecoration(labelText: 'Prerequisites'),
                  controller: preC,
                ),
                TextField(
                  decoration:
                  const InputDecoration(labelText: 'Enrollment Fee (₹)'),
                  keyboardType: TextInputType.number,
                  controller: feeC,
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Offline Contact Phone',
                  ),
                  keyboardType: TextInputType.phone,
                  controller: phoneC,
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Offline Contact Email',
                  ),
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
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
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
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                final fee = int.tryParse(feeC.text.trim()) ?? 0;

                final docRef = FirebaseFirestore.instance
                    .collection('hackathons')
                    .doc();
                String qrUrl = '';

                try {
                  if (qrBytes != null) {
                    final ref = FirebaseStorage.instance
                        .ref()
                        .child('hackathon_qr/${docRef.id}.png');
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
                    'logoPath': 'assets/hack1.png',
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
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) => _updateTime(),
    );
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
        'Expired',
        style: TextStyle(color: Colors.red),
      );
    }
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;
    return Text(
      '⏳ ${days}d ${hours}h ${minutes}m ${seconds}s',
      style: const TextStyle(fontSize: 12),
    );
  }
}
