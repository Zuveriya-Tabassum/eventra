import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'registration_form.dart';
import '../../core/presentation/app_drawer.dart';

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
  String? _currentUserName;
  List<_VenueBooking> _allVenueBookings = [];

  final List<String> _fixedHalls = const [
    'Rnd lab',
    'Sir Visweshraya hall',
    'c.v raman hall',
    'Main auditorium',
    'Seminar hall 1',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initData();

    staticHackathons = [
      Hackathon(
        id: 'static_h1',
        logoPath: 'assets/hack1.png',
        name: 'Campus Code Clash',
        description:
            'A 24-hour coding challenge for campus students.\nTest your logic, speed, and teamwork in real-world programming scenarios.',
        venue: 'Main Auditorium',
        deadline: DateTime.now().add(
          const Duration(days: 2, hours: 5, minutes: 30),
        ),
        organizer: 'Dept. of CSE - Tech Club',
        prerequisites: 'Open for all CSE/IT students. Basic C/C++ required.',
        createdBy: 'system',
        fee: 200,
        qrUrl: '',
        offlineContactPhone: '9876543210',
        offlineContactEmail: 'organizer@clg.edu',
      ),
    ];
  }

  Future<void> _initData() async {
    await _loadUserData();
    await _loadAllVenueBookings();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (mounted) {
      setState(() {
        _role = snap.data()?['role'] as String? ?? 'Participant';
        _currentUserName = snap.data()?['name'] as String? ?? 'Unknown';
      });
    }
  }

  Future<void> _loadAllVenueBookings() async {
    if (!mounted) return;
    final now = DateTime.now();
    final List<_VenueBooking> items = [];

    final annSnap = await FirebaseFirestore.instance
        .collection('announcements')
        .get();
    for (var d in annSnap.docs) {
      final data = d.data();
      final venue = (data['venue'] ?? '').toString();
      if (venue.isEmpty) continue;
      final date = (data['date'] as Timestamp).toDate();
      final start = DateTime(
        date.year,
        date.month,
        date.day,
        data['timeHour'] ?? 0,
        data['timeMinute'] ?? 0,
      );
      if (start.isBefore(now)) continue;
      items.add(
        _VenueBooking(
          source: 'announcement',
          title: data['title'] ?? '',
          venue: venue,
          from: start,
          to: DateTime(date.year, date.month, date.day, 23, 59),
        ),
      );
    }

    final hackSnap = await FirebaseFirestore.instance
        .collection('hackathons')
        .get();
    for (var d in hackSnap.docs) {
      final data = d.data();
      final venue = (data['venue'] ?? '').toString();
      if (venue.isEmpty) continue;
      final deadline = (data['deadline'] as Timestamp).toDate();
      if (deadline.isBefore(now)) continue;
      items.add(
        _VenueBooking(
          source: 'hackathon',
          title: data['name'] ?? '',
          venue: venue,
          from: deadline,
          to: DateTime(deadline.year, deadline.month, deadline.day, 23, 59),
        ),
      );
    }

    final wsSnap = await FirebaseFirestore.instance
        .collection('workshops')
        .get();
    for (var d in wsSnap.docs) {
      final data = d.data();
      final venue = (data['venue'] ?? '').toString();
      if (venue.isEmpty) continue;
      final deadline = (data['deadline'] as Timestamp).toDate();
      if (deadline.isBefore(now)) continue;
      items.add(
        _VenueBooking(
          source: 'workshop',
          title: data['name'] ?? '',
          venue: venue,
          from: deadline,
          to: DateTime(deadline.year, deadline.month, deadline.day, 23, 59),
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _allVenueBookings = items;
    });
  }

  bool _conflictsWithExisting({
    required String venue,
    required DateTime date,
    String? ignoreId,
  }) {
    final candidateStart = DateTime(date.year, date.month, date.day);
    final candidateEnd = DateTime(date.year, date.month, date.day, 23, 59);

    for (final b in _allVenueBookings) {
      if (b.venue.trim().toLowerCase() != venue.trim().toLowerCase()) continue;
      final overlaps =
          !candidateEnd.isBefore(b.from) && !candidateStart.isAfter(b.to);
      if (overlaps) return true;
    }
    return false;
  }

  bool get _isAdmin => _role == 'Admin';
  bool get _isClubHead => _role == 'Club Head';

  List<Hackathon> _filterByTab(List<Hackathon> all, int tabIndex) {
    if (tabIndex == 0) return all.where((h) => h.status == 'upcoming').toList();
    if (tabIndex == 1) return all.where((h) => h.status == 'ongoing').toList();
    return all.where((h) => h.status == 'completed').toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Hackathons'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllVenueBookings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('hackathons').snapshots(),
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
                  createdByName: data['createdByName'] as String?,
                  updatedByName: data['updatedByName'] as String?,
                  updatedAt: data['updatedAt'] is Timestamp
                      ? (data['updatedAt'] as Timestamp).toDate()
                      : null,
                  fee: (data['fee'] ?? 0) as int,
                  qrUrl: data['qrUrl'] ?? '',
                  offlineContactPhone: data['offlineContactPhone'] ?? '',
                  offlineContactEmail: data['offlineContactEmail'] ?? '',
                  status: data['status'] ?? 'upcoming',
                ),
              );
            }
          }
          final all = [...staticHackathons, ...dynamicHackathons];
          return TabBarView(
            controller: _tabController,
            children: [
              _buildHackathonList(_filterByTab(all, 0), user?.uid),
              _buildHackathonList(_filterByTab(all, 1), user?.uid),
              _buildHackathonList(_filterByTab(all, 2), user?.uid),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHackathonList(List<Hackathon> list, String? uid) {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        if (_isAdmin || _isClubHead)
          _AddHackathonCard(
            fixedHalls: _fixedHalls,
            currentUserName: _currentUserName ?? 'Unknown',
            checkConflict: _conflictsWithExisting,
            onAdded: _loadAllVenueBookings,
          ),
        if (list.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No hackathons found.'),
            ),
          )
        else
          ...list.map(
            (h) => HackathonCard(
              hackathon: h,
              currentUserId: uid ?? '',
              role: _role ?? 'Participant',
              currentUserName: _currentUserName ?? 'Unknown',
              fixedHalls: _fixedHalls,
              checkConflict: _conflictsWithExisting,
              onUpdated: _loadAllVenueBookings,
            ),
          ),
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
  final String? createdByName;
  final String? updatedByName;
  final DateTime? updatedAt;
  final int fee;
  final String qrUrl;
  final String offlineContactPhone;
  final String offlineContactEmail;
  final String status;

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
    this.createdByName,
    this.updatedByName,
    this.updatedAt,
    required this.fee,
    required this.qrUrl,
    required this.offlineContactPhone,
    required this.offlineContactEmail,
    this.status = 'upcoming',
  });
}

class _VenueBooking {
  final String source, title, venue;
  final DateTime from, to;
  _VenueBooking({
    required this.source,
    required this.title,
    required this.venue,
    required this.from,
    required this.to,
  });
}

class HackathonCard extends StatefulWidget {
  final Hackathon hackathon;
  final String currentUserId, role, currentUserName;
  final List<String> fixedHalls;
  final bool Function({required String venue, required DateTime date})
  checkConflict;
  final VoidCallback onUpdated;

  const HackathonCard({
    super.key,
    required this.hackathon,
    required this.currentUserId,
    required this.role,
    required this.currentUserName,
    required this.fixedHalls,
    required this.checkConflict,
    required this.onUpdated,
  });

  @override
  State<HackathonCard> createState() => _HackathonCardState();
}

class _HackathonCardState extends State<HackathonCard> {
  bool isExpanded = false;

  bool get _canEdit =>
      widget.role == 'Admin' ||
      (widget.role == 'Club Head' &&
          widget.hackathon.createdBy == widget.currentUserId);

  Future<void> _delete() async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Delete?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Yes', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) {
      await FirebaseFirestore.instance
          .collection('hackathons')
          .doc(widget.hackathon.id)
          .delete();
      widget.onUpdated();
    }
  }

  void _showParticipants() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('hackathons')
            .doc(widget.hackathon.id)
            .collection('enrollments')
            .snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Participants (${docs.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (c, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(d['name'] ?? 'Unknown'),
                      subtitle: Text(
                        'Roll: ${d['rollNo'] ?? 'N/A'} • Branch: ${d['branch'] ?? 'N/A'}',
                      ),
                      trailing: Text(
                        d['email'] ?? '',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit() async {
    final h = widget.hackathon;
    final nameC = TextEditingController(text: h.name);
    final descC = TextEditingController(text: h.description);
    final feeC = TextEditingController(text: h.fee.toString());
    final phoneC = TextEditingController(text: h.offlineContactPhone);
    final emailC = TextEditingController(text: h.offlineContactEmail);

    String? selectedHall;
    final otherHallC = TextEditingController();
    final roomNoC = TextEditingController();

    if (widget.fixedHalls.contains(h.venue)) {
      selectedHall = h.venue;
    } else if (h.venue.toLowerCase().startsWith('room ')) {
      selectedHall = 'Room no';
      roomNoC.text = h.venue.substring(5);
    } else {
      selectedHall = 'Other hall';
      otherHallC.text = h.venue;
    }

    DateTime deadline = h.deadline;
    String status = h.status;
    Uint8List? qrBytes;
    String? venueWarning;

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setS) {
          String resolveV() {
            if (selectedHall == 'Other hall') return otherHallC.text.trim();
            if (selectedHall == 'Room no') {
              return roomNoC.text.trim().isEmpty
                  ? ''
                  : 'Room ${roomNoC.text.trim()}';
            }
            return selectedHall ?? '';
          }

          void checkV() {
            final v = resolveV();
            if (v.isNotEmpty &&
                widget.checkConflict(venue: v, date: deadline)) {
              setS(() => venueWarning = 'Warning: Venue might be booked!');
            } else {
              setS(() => venueWarning = null);
            }
          }

          return AlertDialog(
            title: const Text('Edit Hackathon'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameC,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: descC,
                    decoration: const InputDecoration(labelText: 'Desc'),
                    maxLines: 2,
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedHall,
                    items: [
                      ...widget.fixedHalls.map(
                        (e) => DropdownMenuItem(value: e, child: Text(e)),
                      ),
                      const DropdownMenuItem(
                        value: 'Other hall',
                        child: Text('Other'),
                      ),
                      const DropdownMenuItem(
                        value: 'Room no',
                        child: Text('Room'),
                      ),
                    ],
                    onChanged: (v) {
                      setS(() => selectedHall = v);
                      checkV();
                    },
                    decoration: const InputDecoration(labelText: 'Venue'),
                  ),
                  if (selectedHall == 'Other hall')
                    TextField(
                      controller: otherHallC,
                      decoration: const InputDecoration(labelText: 'Hall Name'),
                      onChanged: (_) => checkV(),
                    ),
                  if (selectedHall == 'Room no')
                    TextField(
                      controller: roomNoC,
                      decoration: const InputDecoration(labelText: 'Room No'),
                      onChanged: (_) => checkV(),
                    ),
                  if (venueWarning != null)
                    Text(
                      venueWarning!,
                      style: const TextStyle(color: Colors.red, fontSize: 10),
                    ),

                  DropdownButtonFormField<String>(
                    value: status,
                    items: const [
                      DropdownMenuItem(
                        value: 'upcoming',
                        child: Text('Upcoming'),
                      ),
                      DropdownMenuItem(
                        value: 'ongoing',
                        child: Text('Ongoing'),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Completed'),
                      ),
                    ],
                    onChanged: (v) => setS(() => status = v!),
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),

                  TextField(
                    controller: feeC,
                    decoration: const InputDecoration(labelText: 'Fee'),
                    keyboardType: TextInputType.number,
                  ),
                  ListTile(
                    title: Text(
                      'Deadline: ${DateFormat('MMM dd, HH:mm').format(deadline)}',
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: c,
                        initialDate: deadline,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) {
                        final t = await showTimePicker(
                          context: c,
                          initialTime: TimeOfDay.fromDateTime(deadline),
                        );
                        if (t != null) {
                          setS(
                            () => deadline = DateTime(
                              d.year,
                              d.month,
                              d.day,
                              t.hour,
                              t.minute,
                            ),
                          );
                          checkV();
                        }
                      }
                    },
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final res = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        withData: true,
                      );
                      if (res != null) {
                        setS(() => qrBytes = res.files.single.bytes);
                      }
                    },
                    icon: const Icon(Icons.qr_code),
                    label: Text(qrBytes == null ? 'Change QR' : 'QR Selected'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  String qUrl = h.qrUrl;
                  if (qrBytes != null) {
                    final ref = FirebaseStorage.instance.ref().child(
                      'hackathon_qr/${h.id}.png',
                    );
                    await ref.putData(
                      qrBytes!,
                      SettableMetadata(contentType: 'image/png'),
                    );
                    qUrl = await ref.getDownloadURL();
                  }
                  await FirebaseFirestore.instance
                      .collection('hackathons')
                      .doc(h.id)
                      .update({
                        'name': nameC.text.trim(),
                        'description': descC.text.trim(),
                        'venue': resolveV(),
                        'deadline': deadline,
                        'status': status,
                        'fee': int.tryParse(feeC.text) ?? 0,
                        'qrUrl': qUrl,
                        'updatedByName': widget.currentUserName,
                        'offlineContactPhone': phoneC.text.trim(),
                        'offlineContactEmail': emailC.text.trim(),
                      });
                  widget.onUpdated();
                  if (mounted) Navigator.pop(c);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hackathon;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          h.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${DateFormat('MMM dd').format(h.deadline)} • ${h.venue}',
        ),
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.description),
                const SizedBox(height: 8),
                if (h.qrUrl.isNotEmpty) Image.network(h.qrUrl, height: 120),
                const SizedBox(height: 8),
                Text(
                  'Status: ${h.status.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (h.createdByName != null)
                  Text(
                    'Created by: ${h.createdByName}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                if (h.updatedByName != null)
                  Text(
                    'Last edited by: ${h.updatedByName}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_canEdit) ...[
                      IconButton(
                        icon: const Icon(Icons.people),
                        onPressed: _showParticipants,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _edit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: _delete,
                      ),
                    ],
                    if (widget.role == 'Participant' && h.status == 'upcoming')
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegistrationFormPage(
                                eventId: h.id,
                                eventType: 'hackathon',
                                eventName: h.name,
                                venue: h.venue,
                                deadline: h.deadline,
                                fee: h.fee,
                                qrUrl: h.qrUrl,
                                offlineContactPhone: h.offlineContactPhone,
                                offlineContactEmail: h.offlineContactEmail,
                              ),
                            ),
                          );
                        },
                        child: const Text('Register'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddHackathonCard extends StatefulWidget {
  final List<String> fixedHalls;
  final String currentUserName;
  final bool Function({required String venue, required DateTime date})
  checkConflict;
  final VoidCallback onAdded;

  const _AddHackathonCard({
    required this.fixedHalls,
    required this.currentUserName,
    required this.checkConflict,
    required this.onAdded,
  });

  @override
  State<_AddHackathonCard> createState() => _AddHackathonCardState();
}

class _AddHackathonCardState extends State<_AddHackathonCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        title: const Text('Add New Hackathon'),
        onTap: () => _showAddDialog(context),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final nameC = TextEditingController();
    final descC = TextEditingController();
    final feeC = TextEditingController(text: '0');
    final orgC = TextEditingController();
    final preC = TextEditingController();
    final phoneC = TextEditingController();
    final emailC = TextEditingController();

    String? selectedHall;
    final otherHallC = TextEditingController();
    final roomNoC = TextEditingController();
    DateTime deadline = DateTime.now().add(const Duration(days: 7));
    Uint8List? qrBytes;
    String? venueWarning;

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setS) {
          String resolveV() {
            if (selectedHall == 'Other hall') return otherHallC.text.trim();
            if (selectedHall == 'Room no') {
              return roomNoC.text.trim().isEmpty
                  ? ''
                  : 'Room ${roomNoC.text.trim()}';
            }
            return selectedHall ?? '';
          }

          void checkV() {
            final v = resolveV();
            if (v.isNotEmpty &&
                widget.checkConflict(venue: v, date: deadline)) {
              setS(
                () => venueWarning = 'Warning: Venue might be already booked!',
              );
            } else {
              setS(() => venueWarning = null);
            }
          }

          return AlertDialog(
            title: const Text('New Hackathon'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameC,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: descC,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedHall,
                    items: [
                      ...widget.fixedHalls.map(
                        (e) => DropdownMenuItem(value: e, child: Text(e)),
                      ),
                      const DropdownMenuItem(
                        value: 'Other hall',
                        child: Text('Other'),
                      ),
                      const DropdownMenuItem(
                        value: 'Room no',
                        child: Text('Room'),
                      ),
                    ],
                    onChanged: (v) {
                      setS(() => selectedHall = v);
                      checkV();
                    },
                    decoration: const InputDecoration(labelText: 'Venue'),
                  ),
                  if (selectedHall == 'Other hall')
                    TextField(
                      controller: otherHallC,
                      decoration: const InputDecoration(labelText: 'Hall Name'),
                      onChanged: (_) => checkV(),
                    ),
                  if (selectedHall == 'Room no')
                    TextField(
                      controller: roomNoC,
                      decoration: const InputDecoration(labelText: 'Room No'),
                      onChanged: (_) => checkV(),
                    ),
                  if (venueWarning != null)
                    Text(
                      venueWarning!,
                      style: const TextStyle(color: Colors.red, fontSize: 10),
                    ),
                  TextField(
                    controller: feeC,
                    decoration: const InputDecoration(labelText: 'Fee'),
                    keyboardType: TextInputType.number,
                  ),
                  ListTile(
                    title: Text(
                      'Deadline: ${DateFormat('MMM dd, HH:mm').format(deadline)}',
                    ),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: c,
                        initialDate: deadline,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) {
                        final t = await showTimePicker(
                          context: c,
                          initialTime: TimeOfDay.fromDateTime(deadline),
                        );
                        if (t != null) {
                          setS(
                            () => deadline = DateTime(
                              d.year,
                              d.month,
                              d.day,
                              t.hour,
                              t.minute,
                            ),
                          );
                          checkV();
                        }
                      }
                    },
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final res = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        withData: true,
                      );
                      if (res != null) {
                        setS(() => qrBytes = res.files.single.bytes);
                      }
                    },
                    icon: const Icon(Icons.qr_code),
                    label: Text(
                      qrBytes == null ? 'Upload Payment QR' : 'QR Selected',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;
                  final docRef = FirebaseFirestore.instance
                      .collection('hackathons')
                      .doc();
                  String qUrl = '';
                  if (qrBytes != null) {
                    final ref = FirebaseStorage.instance.ref().child(
                      'hackathon_qr/${docRef.id}.png',
                    );
                    await ref.putData(
                      qrBytes!,
                      SettableMetadata(contentType: 'image/png'),
                    );
                    qUrl = await ref.getDownloadURL();
                  }
                  await docRef.set({
                    'name': nameC.text.trim(),
                    'description': descC.text.trim(),
                    'venue': resolveV(),
                    'deadline': deadline,
                    'status': 'upcoming',
                    'fee': int.tryParse(feeC.text) ?? 0,
                    'qrUrl': qUrl,
                    'createdBy': user.uid,
                    'createdByName': widget.currentUserName,
                    'organizer': orgC.text.trim(),
                    'prerequisites': preC.text.trim(),
                    'offlineContactPhone': phoneC.text.trim(),
                    'offlineContactEmail': emailC.text.trim(),
                  });
                  widget.onAdded();
                  if (mounted) Navigator.pop(c);
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }
}
