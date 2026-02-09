import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'event_registration_form.dart';

class ClubEventsApp extends StatelessWidget {
  const ClubEventsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        fontFamily: 'Poppins',
        brightness: Brightness.light,
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF3E5F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Club Events',
        home: ClubEventListPage(
          isAdmin: true,                 // TODO: set from login/role
          currentUserId: 'clubHead123',  // TODO: user id from auth
        ),
      ),
    );
  }
}

class ClubEventListPage extends StatefulWidget {
  final bool isAdmin;
  final String currentUserId;

  const ClubEventListPage({
    super.key,
    required this.isAdmin,
    required this.currentUserId,
  });

  @override
  State<ClubEventListPage> createState() => _ClubEventListPageState();
}

class _ClubEventListPageState extends State<ClubEventListPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<ClubEvent> clubEvents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    clubEvents.addAll([
      ClubEvent(
        id: 'e1',
        createdBy: 'system',
        lastEditedBy: 'system',
        lastEditedAt: DateTime.now(),
        logoPath: 'assets/images/club_logo1.png',
        name: 'Robotics Challenge',
        description:
        'Compete with your robotics creations!\nTeams battle in fun tasks to test design and programming skills.',
        venue: 'Robotics Lab',
        deadline: DateTime.now().add(const Duration(days: 3, hours: 2)),
        organizer: 'Robotics Club',
        prerequisites: 'Open for all. Basic robotics knowledge preferred.',
        backgroundImage: 'assets/images/img.png',
        contactName: 'Robo Lead',
        contactPhone: '+91 98765 00001',
        contactEmail: 'robotics@college.edu',
        paymentRequired: true,
      ),
      ClubEvent(
        id: 'e2',
        createdBy: 'system',
        lastEditedBy: 'system',
        lastEditedAt: DateTime.now(),
        logoPath: 'assets/images/club_logo2.png',
        name: 'Photography Marathon',
        description:
        'Capture the beauty around the campus in 12 hours.\nSubmit your best shots to win exciting prizes.',
        venue: 'Campus Grounds',
        deadline: DateTime.now().add(const Duration(hours: 15)),
        organizer: 'Photography Club',
        prerequisites: 'Bring your camera/lens. Open to all.',
        backgroundImage: 'assets/images/img.png',
        contactName: 'Photo Head',
        contactPhone: '+91 98765 00002',
        contactEmail: 'photo@college.edu',
        paymentRequired: false,
      ),
      ClubEvent(
        id: 'e3',
        createdBy: 'system',
        lastEditedBy: 'system',
        lastEditedAt: DateTime.now().subtract(const Duration(hours: 5)),
        logoPath: 'assets/images/club_logo3.png',
        name: 'Music Jam Session',
        description:
        'Collaborate with fellow musicians and jam live!\nExperience music and fun with different instruments.',
        venue: 'Auditorium',
        deadline: DateTime.now().subtract(const Duration(hours: 4)),
        organizer: 'Music Club',
        prerequisites: 'Open for all musicians. Bring instruments.',
        backgroundImage: 'assets/images/img.png',
        contactName: 'Music Co‑ordinator',
        contactPhone: '+91 98765 00003',
        contactEmail: 'music@college.edu',
        paymentRequired: false,
      ),
    ]);
  }

  List<ClubEvent> getUpcoming() {
    final now = DateTime.now();
    return clubEvents
        .where((e) => e.deadline.isAfter(now.add(const Duration(hours: 24))))
        .toList();
  }

  List<ClubEvent> getOngoing() {
    final now = DateTime.now();
    return clubEvents.where((e) {
      final diff = e.deadline.difference(now);
      return diff.inHours <= 24 && !diff.isNegative;
    }).toList();
  }

  List<ClubEvent> getCompleted() {
    final now = DateTime.now();
    return clubEvents.where((e) => e.deadline.isBefore(now)).toList();
  }

  void _openAddOrEditDialog({ClubEvent? existing}) async {
    final result = await showModalBottomSheet<ClubEvent>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EventEditSheet(
          existing: existing,
          currentUserId: widget.currentUserId,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      final idx = clubEvents.indexWhere((e) => e.id == result.id);
      if (idx == -1) {
        clubEvents.add(result);
      } else {
        clubEvents[idx] = result;
      }
    });
  }

  void _deleteEvent(ClubEvent event) {
    setState(() {
      clubEvents.removeWhere((e) => e.id == event.id);
    });
  }

  bool _canEditOrDelete(ClubEvent e) {
    return widget.isAdmin || e.lastEditedBy == widget.currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Club Events'),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClubEventList(getUpcoming()),
          _buildClubEventList(getOngoing()),
          _buildClubEventList(getCompleted()),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
        onPressed: () => _openAddOrEditDialog(),
      )
          : null,
    );
  }

  Widget _buildClubEventList(List<ClubEvent> list) {
    return list.isEmpty
        ? const Center(child: Text('No club events found.'))
        : ListView(
      padding: const EdgeInsets.all(10),
      children: [
        ...list.map(
              (event) => ClubEventCard(
            event: event,
            canEditOrDelete: _canEditOrDelete(event),
            onEdit: () => _openAddOrEditDialog(existing: event),
            onDelete: () => _deleteEvent(event),
            currentUserId: widget.currentUserId,
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

class ClubEvent {
  final String id;
  final String createdBy;
  final String lastEditedBy;
  final DateTime lastEditedAt;

  final String logoPath;
  final String name;
  final String description;
  final String venue;
  final DateTime deadline;
  final String organizer;
  final String prerequisites;
  final String backgroundImage;

  final String contactName;
  final String contactPhone;
  final String contactEmail;

  final bool paymentRequired;

  ClubEvent({
    required this.id,
    required this.createdBy,
    required this.lastEditedBy,
    required this.lastEditedAt,
    required this.logoPath,
    required this.name,
    required this.description,
    required this.venue,
    required this.deadline,
    required this.organizer,
    required this.prerequisites,
    required this.backgroundImage,
    required this.contactName,
    required this.contactPhone,
    required this.contactEmail,
    required this.paymentRequired,
  });
}

class ClubEventCard extends StatefulWidget {
  final ClubEvent event;
  final bool canEditOrDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String currentUserId;

  const ClubEventCard({
    super.key,
    required this.event,
    required this.canEditOrDelete,
    required this.onEdit,
    required this.onDelete,
    required this.currentUserId,
  });

  @override
  State<ClubEventCard> createState() => _ClubEventCardState();
}

class _ClubEventCardState extends State<ClubEventCard> {
  bool isExpanded = false;
  bool markedRead = false;

  void toggleExpanded() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: event.backgroundImage.startsWith('http')
                ? Image.network(event.backgroundImage, fit: BoxFit.cover)
                : Image.asset(event.backgroundImage, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.85)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
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
                        event.name.substring(0, 1),
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  event.name,
                                  style: TextStyle(
                                    fontSize: isExpanded ? 18 : 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    DateFormat('MMM dd, yyyy – hh:mm a')
                                        .format(event.deadline),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                  CountdownTimerClub(deadline: event.deadline),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Last edited: ${DateFormat('MMM dd, HH:mm').format(event.lastEditedAt)}',
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(event.description),
                          const SizedBox(height: 4),
                          Text(
                            '📍 ${event.venue}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (!isExpanded)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                    backgroundColor: Colors.teal),
                                onPressed: toggleExpanded,
                                child: const Text(
                                  'View Details',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.white),
                                ),
                              ),
                            )
                        ],
                      ),
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🏢 Organized By: ${event.organizer}'),
                        const SizedBox(height: 5),
                        Text('✅ Prerequisites: ${event.prerequisites}'),
                        const SizedBox(height: 8),
                        Text('👤 Contact: ${event.contactName}'),
                        Text('📞 ${event.contactPhone}'),
                        Text('✉️  ${event.contactEmail}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.canEditOrDelete)
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.teal),
                              onPressed: widget.onEdit,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: widget.onDelete,
                            ),
                          ],
                        ),
                      const Spacer(),
                      if (event.deadline.isAfter(DateTime.now()))
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal),
                          onPressed: () {
                            if (event.paymentRequired) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClubRegistrationFormPage(
                                    eventName: event.name,
                                  ),
                                ),
                              );
                            } else {
                              setState(() => markedRead = !markedRead);
                            }
                          },
                          child: Text(
                            event.paymentRequired
                                ? 'Enroll'
                                : (markedRead ? 'Marked' : 'Mark as read'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CountdownTimerClub extends StatefulWidget {
  final DateTime deadline;
  const CountdownTimerClub({super.key, required this.deadline});

  @override
  State<CountdownTimerClub> createState() => _CountdownTimerClubState();
}

class _CountdownTimerClubState extends State<CountdownTimerClub> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
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
      return const Text("Expired", style: TextStyle(color: Colors.red));
    }
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final mins = _timeLeft.inMinutes % 60;
    final secs = _timeLeft.inSeconds % 60;
    return Text(
      "⏳ ${days}d ${hours}h ${mins}m ${secs}s",
      style: const TextStyle(fontSize: 12),
    );
  }
}

/// Bottom sheet form used by admin/club head
class EventEditSheet extends StatefulWidget {
  final ClubEvent? existing;
  final String currentUserId;

  const EventEditSheet({
    super.key,
    required this.existing,
    required this.currentUserId,
  });

  @override
  State<EventEditSheet> createState() => _EventEditSheetState();
}

class _EventEditSheetState extends State<EventEditSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _venueCtrl;
  late TextEditingController _organizerCtrl;
  late TextEditingController _preReqCtrl;
  late TextEditingController _contactNameCtrl;
  late TextEditingController _contactPhoneCtrl;
  late TextEditingController _contactEmailCtrl;
  late TextEditingController _bgImageCtrl;

  late DateTime _deadline;
  bool _paymentRequired = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.name ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _venueCtrl = TextEditingController(text: e?.venue ?? '');
    _organizerCtrl = TextEditingController(text: e?.organizer ?? '');
    _preReqCtrl = TextEditingController(text: e?.prerequisites ?? '');
    _contactNameCtrl = TextEditingController(text: e?.contactName ?? '');
    _contactPhoneCtrl = TextEditingController(text: e?.contactPhone ?? '');
    _contactEmailCtrl = TextEditingController(text: e?.contactEmail ?? '');
    _bgImageCtrl = TextEditingController(text: e?.backgroundImage ?? '');
    _deadline = e?.deadline ?? DateTime.now().add(const Duration(days: 1));
    _paymentRequired = e?.paymentRequired ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _venueCtrl.dispose();
    _organizerCtrl.dispose();
    _preReqCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _contactEmailCtrl.dispose();
    _bgImageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
    );
    if (time == null) return;
    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final existing = widget.existing;

    final newEvent = ClubEvent(
      id: existing?.id ?? 'event_${now.millisecondsSinceEpoch}',
      createdBy: existing?.createdBy ?? widget.currentUserId,
      lastEditedBy: widget.currentUserId,
      lastEditedAt: now,
      logoPath: existing?.logoPath ?? 'assets/images/club_logo1.png',
      name: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      venue: _venueCtrl.text.trim(),
      deadline: _deadline,
      organizer: _organizerCtrl.text.trim(),
      prerequisites: _preReqCtrl.text.trim(),
      backgroundImage: _bgImageCtrl.text.trim().isEmpty
          ? 'assets/images/img.png'
          : _bgImageCtrl.text.trim(),
      contactName: _contactNameCtrl.text.trim(),
      contactPhone: _contactPhoneCtrl.text.trim(),
      contactEmail: _contactEmailCtrl.text.trim(),
      paymentRequired: _paymentRequired,
    );

    Navigator.pop(context, newEvent);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 12, bottom: 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                widget.existing == null ? 'Add New Event' : 'Edit Event',
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _venueCtrl,
                decoration: const InputDecoration(labelText: 'Venue'),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _organizerCtrl,
                decoration: const InputDecoration(labelText: 'Organized by'),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _preReqCtrl,
                decoration: const InputDecoration(labelText: 'Prerequisites'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Deadline: ${DateFormat('MMM dd, yyyy – hh:mm a').format(_deadline)}',
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDeadline,
                    child: const Text('Pick date & time'),
                  ),
                ],
              ),
              const Divider(),
              TextFormField(
                controller: _contactNameCtrl,
                decoration:
                const InputDecoration(labelText: 'Organizer name'),
              ),
              TextFormField(
                controller: _contactPhoneCtrl,
                decoration:
                const InputDecoration(labelText: 'Contact phone'),
              ),
              TextFormField(
                controller: _contactEmailCtrl,
                decoration:
                const InputDecoration(labelText: 'Contact email'),
              ),
              TextFormField(
                controller: _bgImageCtrl,
                decoration: const InputDecoration(
                    labelText: 'Background image URL / asset path'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Payment required'),
                value: _paymentRequired,
                onChanged: (v) => setState(() => _paymentRequired = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                  onPressed: _submit,
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
