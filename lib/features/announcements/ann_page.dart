// lib/features/announcements/ann_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

import '../../data/models/ann_models.dart';
import 'ann_calendar.dart';
import '../../core/presentation/app_drawer.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage>
    with SingleTickerProviderStateMixin {
  String _search = '';
  AnnouncementCategory? _filterCategory;
  int _currentIndex = 0;

  final Map<String, bool> _archivedMap = {};
  final Map<String, bool> _readMap = {};
  final ScrollController _listScrollController = ScrollController();

  bool _isPrivileged = false;
  String _currentUserName = 'Unknown';
  String _currentStudentId = 'Unknown';
  bool _loadingAnnouncements = true;

  final CollectionReference _annRef = FirebaseFirestore.instance.collection(
    'announcements',
  );

  List<Announcement> _announcements = [];

  List<_VenueBooking> _allVenueBookings = [];

  late AnimationController _segController;

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
    _loadUserData();
    _loadAnnouncementState();
    _initAnnouncementsAndBookings();

    _segController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _segController.forward();
  }

  Future<void> _initAnnouncementsAndBookings() async {
    await _loadAnnouncements();
    await _loadAllVenueBookings();
  }

  @override
  void dispose() {
    _segController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = snap.data();
    final role = data?['role'];

    setState(() {
      _isPrivileged = role == 'Admin' || role == 'Club Head';
      _currentUserName = data?['name'] ?? 'Unknown';
      _currentStudentId = data?['studentId'] ?? 'Unknown';
    });
  }

  Future<void> _loadAnnouncements() async {
    final snap = await _annRef.orderBy('date').get();

    final List<Announcement> list = [];

    for (var d in snap.docs) {
      final data = d.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final time = TimeOfDay(
        hour: data['timeHour'] ?? 0,
        minute: data['timeMinute'] ?? 0,
      );
      final catName = (data['category'] ?? 'notice') as String;

      final category = AnnouncementCategory.values.firstWhere(
        (c) => c.name == catName,
        orElse: () => AnnouncementCategory.notice,
      );

      final readersSnap = await d.reference.collection('readers').get();
      final readers = readersSnap.docs.map((rd) => rd.data()).toList();

      list.add(
        Announcement(
          id: d.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          venue: data['venue'] ?? '',
          date: date,
          time: time,
          category: category,
          isImportant: data['isImportant'] == true,
          isPinned: data['isPinned'] == true,
          targetType: data['targetType'] as String?,
          targetId: data['targetId'] as String?,
          createdByName: data['createdByName'] as String?,
          updatedByName: data['updatedByName'] as String?,
          createdAt: data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
          updatedAt: data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
          readers: readers,
          posterUrl: data['posterUrl'] as String?,
        ),
      );
    }

    setState(() {
      _announcements = list;
      _loadingAnnouncements = false;
    });
  }

  Future<void> _loadAnnouncementState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('announcement_state')
        .get();

    setState(() {
      for (final doc in snap.docs) {
        final data = doc.data();
        _archivedMap[doc.id] = data['archived'] == true;
        _readMap[doc.id] = data['read'] == true;
      }
    });
  }

  Future<void> _setAnnouncementState(
    Announcement ann, {
    bool? archived,
    bool? read,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('announcement_state')
        .doc(ann.id)
        .set({
          if (archived != null) 'archived': archived,
          if (read != null) 'read': read,
        }, SetOptions(merge: true));
  }

  List<Announcement> get _filtered {
    final list = _announcements.where((a) {
      final matchesSearch = a.title.toLowerCase().contains(
        _search.toLowerCase(),
      );
      final matchesCategory =
          _filterCategory == null || a.category == _filterCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    list.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return b.isPinned ? 1 : -1;
      }
      if (a.isImportant != b.isImportant) {
        return b.isImportant ? 1 : -1;
      }
      return a.date.compareTo(b.date);
    });

    return list;
  }

  DateTime _combineAnnouncement(Announcement a) => DateTime(
    a.date.year,
    a.date.month,
    a.date.day,
    a.time.hour,
    a.time.minute,
  );

  Future<void> _loadAllVenueBookings() async {
    final now = DateTime.now();
    final List<_VenueBooking> items = [];

    for (final a in _announcements) {
      if (a.venue.isEmpty) continue;
      final start = _combineAnnouncement(a);
      if (start.isBefore(now)) continue;
      final end = DateTime(a.date.year, a.date.month, a.date.day, 23, 59);
      items.add(
        _VenueBooking(
          source: 'announcement',
          title: a.title,
          venue: a.venue,
          from: start,
          to: end,
        ),
      );
    }

    final hackSnap = await FirebaseFirestore.instance
        .collection('hackathons')
        .get();
    for (final d in hackSnap.docs) {
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
    for (final d in wsSnap.docs) {
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

    final clubSnap = await FirebaseFirestore.instance
        .collection('club_events')
        .get();
    for (final d in clubSnap.docs) {
      final data = d.data();
      final venue = (data['venue'] ?? '').toString();
      if (venue.isEmpty) continue;
      final date = (data['date'] as Timestamp).toDate();
      if (date.isBefore(now)) continue;
      items.add(
        _VenueBooking(
          source: 'club',
          title: data['title'] ?? '',
          venue: venue,
          from: date,
          to: DateTime(date.year, date.month, date.day, 23, 59),
        ),
      );
    }

    items.sort((a, b) => a.from.compareTo(b.from));

    if (!mounted) return;
    setState(() {
      _allVenueBookings = items;
    });
  }

  bool _conflictsWithExisting({
    required String venue,
    required DateTime date,
    required TimeOfDay time,
    Announcement? ignore,
  }) {
    final candidateStart = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final candidateEnd = DateTime(date.year, date.month, date.day, 23, 59);

    for (final b in _allVenueBookings) {
      if (b.venue.trim().toLowerCase() != venue.trim().toLowerCase()) continue;
      if (ignore != null && b.source == 'announcement') {
        final sameDate =
            b.from.year == ignore.date.year &&
            b.from.month == ignore.date.month &&
            b.from.day == ignore.date.day;
        if (sameDate &&
            ignore.venue.trim().toLowerCase() == b.venue.trim().toLowerCase()) {
          continue;
        }
      }
      final overlaps =
          !candidateEnd.isBefore(b.from) && !candidateStart.isAfter(b.to);
      if (overlaps) return true;
    }
    return false;
  }

  String? _availabilityNote({required String venue, required DateTime date}) {
    DateTime? lastEnd;
    for (final b in _allVenueBookings) {
      if (b.venue.trim().toLowerCase() != venue.trim().toLowerCase()) continue;
      if (b.from.year != date.year ||
          b.from.month != date.month ||
          b.from.day != date.day) {
        continue;
      }
      if (lastEnd == null || b.to.isAfter(lastEnd)) lastEnd = b.to;
    }
    if (lastEnd == null) return null;
    return '$venue is available after ${lastEnd.hour.toString().padLeft(2, '0')}:${lastEnd.minute.toString().padLeft(2, '0')}';
  }

  void _openForm({Announcement? ann}) {
    if (!_isPrivileged) return;

    final titleCtrl = TextEditingController(text: ann?.title ?? '');
    final descCtrl = TextEditingController(text: ann?.description ?? '');

    String? selectedHall;
    final otherHallCtrl = TextEditingController();
    final roomNoCtrl = TextEditingController();

    if (ann != null && ann.venue.isNotEmpty) {
      if (_fixedHalls.contains(ann.venue)) {
        selectedHall = ann.venue;
      } else if (ann.venue.toLowerCase().startsWith('room ')) {
        selectedHall = 'Room no';
        roomNoCtrl.text = ann.venue.substring(5).trim();
      } else {
        selectedHall = 'Other hall';
        otherHallCtrl.text = ann.venue;
      }
    }

    DateTime date = ann?.date ?? DateTime.now();
    TimeOfDay time = ann?.time ?? TimeOfDay.now();
    AnnouncementCategory category =
        ann?.category ?? AnnouncementCategory.notice;
    bool important = ann?.isImportant ?? false;
    bool pinned = ann?.isPinned ?? false;
    String? posterUrl = ann?.posterUrl;
    bool uploadingPoster = false;
    String? errorMessage;
    String? venueNote;

    String? targetType = ann?.targetType;
    String? targetId = ann?.targetId;

    String resolveVenue() {
      if (selectedHall == null) return '';
      if (_fixedHalls.contains(selectedHall)) return selectedHall!;
      if (selectedHall == 'Other hall') return otherHallCtrl.text.trim();
      if (selectedHall == 'Room no') {
        return roomNoCtrl.text.trim().isEmpty
            ? ''
            : 'Room ${roomNoCtrl.text.trim()}';
      }
      return '';
    }

    void validateVenue(StateSetter setDialogState) {
      final venueText = resolveVenue();
      if (venueText.isEmpty) {
        venueNote = null;
        setDialogState(() {});
        return;
      }
      final conflict = _conflictsWithExisting(
        venue: venueText,
        date: date,
        time: time,
        ignore: ann,
      );
      venueNote = conflict
          ? (_availabilityNote(venue: venueText, date: date) ??
                '$venueText not available.')
          : null;
      setDialogState(() {});
    }

    Future<void> pickAndUploadPoster(StateSetter setDialogState) async {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      setDialogState(() => uploadingPoster = true);
      try {
        final cloudinary = CloudinaryPublic(
          'drtvuxjmc',
          'eventra_preset',
          cache: false,
        );
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            image.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        setDialogState(() {
          posterUrl = response.secureUrl;
          uploadingPoster = false;
        });
      } catch (e) {
        setDialogState(() {
          uploadingPoster = false;
          errorMessage = 'Upload failed: $e';
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(ann == null ? 'Add Announcement' : 'Edit Announcement'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errorMessage != null)
                  Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Poster Image',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (posterUrl != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          posterUrl!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 16,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                setDialogState(() => posterUrl = null),
                          ),
                        ),
                      ),
                    ],
                  )
                else if (uploadingPoster)
                  const Center(child: CircularProgressIndicator())
                else
                  OutlinedButton.icon(
                    onPressed: () => pickAndUploadPoster(setDialogState),
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add Poster'),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedHall,
                  decoration: const InputDecoration(labelText: 'Venue'),
                  items: [
                    ..._fixedHalls.map(
                      (h) => DropdownMenuItem(value: h, child: Text(h)),
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
                    selectedHall = v;
                    validateVenue(setDialogState);
                  },
                ),
                if (venueNote != null)
                  Text(
                    venueNote!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ListTile(
                  title: Text('Date: ${DateFormat('dd/MM/yyyy').format(date)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime(2100),
                    );
                    if (p != null) {
                      date = p;
                      validateVenue(setDialogState);
                    }
                  },
                ),
                ListTile(
                  title: Text('Time: ${time.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final p = await showTimePicker(
                      context: context,
                      initialTime: time,
                    );
                    if (p != null) {
                      time = p;
                      validateVenue(setDialogState);
                    }
                  },
                ),
                DropdownButtonFormField<AnnouncementCategory>(
                  value: category,
                  items: AnnouncementCategory.values
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => category = v!),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                SwitchListTile(
                  title: const Text('Important'),
                  value: important,
                  activeColor: Colors.red,
                  onChanged: (v) => setDialogState(() => important = v),
                ),
                SwitchListTile(
                  title: const Text('Pinned'),
                  value: pinned,
                  activeColor: Colors.teal,
                  onChanged: (v) => setDialogState(() => pinned = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final venueFinal = resolveVenue();
                if (titleCtrl.text.isEmpty ||
                    descCtrl.text.isEmpty ||
                    venueFinal.isEmpty) {
                  setDialogState(() => errorMessage = 'Fill all fields.');
                  return;
                }
                final data = {
                  'title': titleCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'venue': venueFinal,
                  'date': Timestamp.fromDate(date),
                  'timeHour': time.hour,
                  'timeMinute': time.minute,
                  'category': category.name,
                  'isImportant': important,
                  'isPinned': pinned,
                  'targetType': targetType,
                  'targetId': targetId,
                  'updatedAt': FieldValue.serverTimestamp(),
                  'updatedByName': _currentUserName,
                  'posterUrl': posterUrl,
                };
                if (ann == null) {
                  final doc = await _annRef.add({
                    ...data,
                    'createdAt': FieldValue.serverTimestamp(),
                    'createdByName': _currentUserName,
                  });
                  setState(
                    () => _announcements.add(
                      Announcement(
                        id: doc.id,
                        title: data['title'] as String,
                        description: data['description'] as String,
                        venue: data['venue'] as String,
                        date: date,
                        time: time,
                        category: category,
                        isImportant: important,
                        isPinned: pinned,
                        createdByName: _currentUserName,
                        updatedByName: _currentUserName,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        readers: [],
                        posterUrl: posterUrl,
                      ),
                    ),
                  );
                } else {
                  await _annRef.doc(ann.id).set(data, SetOptions(merge: true));
                  setState(() {
                    ann
                      ..title = data['title'] as String
                      ..description = data['description'] as String
                      ..venue = data['venue'] as String
                      ..date = date
                      ..time = time
                      ..category = category
                      ..isImportant = important
                      ..isPinned = pinned
                      ..updatedByName = _currentUserName
                      ..updatedAt = DateTime.now()
                      ..posterUrl = posterUrl;
                  });
                }
                Navigator.pop(context);
                _loadAllVenueBookings();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteAnnouncement(Announcement ann) async {
    await _annRef.doc(ann.id).delete();
    setState(() => _announcements.remove(ann));
    _loadAllVenueBookings();
  }

  void _markAsRead(Announcement ann) async {
    if (_readMap[ann.id] == true) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _annRef.doc(ann.id).collection('readers').doc(user.uid).set({
      'uid': user.uid,
      'name': _currentUserName,
      'studentId': _currentStudentId,
      'readAt': FieldValue.serverTimestamp(),
    });
    setState(() {
      _readMap[ann.id] = true;
      ann.readers ??= [];
      ann.readers!.add({
        'uid': user.uid,
        'name': _currentUserName,
        'studentId': _currentStudentId,
        'readAt': Timestamp.now(),
      });
    });
    _setAnnouncementState(ann, read: true);
  }

  void _showReadersList(Announcement ann) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Readers of "${ann.title}"'),
        content: SizedBox(
          width: double.maxFinite,
          child: ann.readers == null || ann.readers!.isEmpty
              ? const Center(child: Text('No one read this.'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: ann.readers!.length,
                  itemBuilder: (context, i) {
                    final r = ann.readers![i];
                    final readAt = r['readAt'] is Timestamp
                        ? (r['readAt'] as Timestamp).toDate()
                        : DateTime.now();
                    return ListTile(
                      dense: true,
                      title: Text(r['name'] ?? 'Unknown'),
                      subtitle: Text('ID: ${r['studentId'] ?? ''}'),
                      trailing: Text(
                        DateFormat('dd/MM HH:mm').format(readAt),
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingAnnouncements) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      drawer: const AppDrawer(currentIndex: 0),
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnnouncements,
          ),
          if (_isPrivileged)
            IconButton(
              icon: const Icon(Icons.event_seat),
              onPressed: () => _showVenueBookings(),
            ),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: _openArchiveSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.campaign),
                  label: Text('List'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.calendar_today),
                  label: Text('Calendar'),
                ),
              ],
              selected: {_currentIndex},
              onSelectionChanged: (set) =>
                  setState(() => _currentIndex = set.first),
            ),
          ),
          Expanded(
            child: _currentIndex == 0
                ? _buildListView()
                : AnnouncementCalendarPage(announcements: _announcements),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        if (_isPrivileged)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.add, color: Colors.white),
              ),
              title: const Text('Add Announcement'),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: _openForm,
            ),
          ),
        Expanded(
          child: _filtered.isEmpty
              ? const Center(child: Text('No announcements.'))
              : ListView.builder(
                  controller: _listScrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _announcementCard(_filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _announcementCard(Announcement ann) {
    final isRead = _readMap[ann.id] == true;
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: ann.isImportant
              ? Colors.red.shade50
              : Colors.blue.shade50,
          child: Icon(
            ann.isImportant ? Icons.priority_high : Icons.campaign,
            color: ann.isImportant ? Colors.red : Colors.blue,
          ),
        ),
        title: Text(
          ann.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isRead ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Text(ann.category.name.toUpperCase()),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ann.posterUrl != null)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(backgroundColor: Colors.black),
                          body: PhotoView(
                            imageProvider: NetworkImage(ann.posterUrl!),
                          ),
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ann.posterUrl!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (ann.venue.isNotEmpty)
                  Text(
                    'Venue: ${ann.venue}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                Text(
                  'Date: ${DateFormat('dd MMM yyyy').format(ann.date)} • ${ann.time.format(context)}',
                ),
                const SizedBox(height: 8),
                Text(ann.description),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!_isPrivileged && !isRead)
                      TextButton.icon(
                        onPressed: () => _markAsRead(ann),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Mark Read'),
                      ),
                    if (_isPrivileged) ...[
                      IconButton(
                        icon: const Icon(Icons.people_outline),
                        onPressed: () => _showReadersList(ann),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openForm(ann: ann),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteAnnouncement(ann),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openArchiveSheet() {
    /* Placeholder for archive sheet logic */
  }
  Future<void> _showVenueBookings() async {
    /* Placeholder for venue bookings logic */
  }
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
