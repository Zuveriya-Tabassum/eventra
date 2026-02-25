// lib/screens/ann_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'ann_models.dart';
import 'ann_calendar.dart';
import 'hackathon_list.dart';
import 'workshop_list.dart';
import 'club.dart';
import 'participant_dashboard.dart';
import 'home.dart';

class AnnouncementPage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const AnnouncementPage({super.key, required this.onToggleTheme});

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
  bool _loadingAnnouncements = true;

  final CollectionReference _annRef = FirebaseFirestore.instance.collection(
    'announcements',
  );

  List<Announcement> _announcements = [];

  List<_VenueBooking> _allVenueBookings = [];
  bool _loadingBookings = false;

  late AnimationController _segController;
  late Animation<double> _segScale;

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
    _loadUserRole();
    _loadAnnouncementState();
    _initAnnouncementsAndBookings();

    _segController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _segScale = Tween<double>(begin: 0.96, end: 1.03).animate(
      CurvedAnimation(parent: _segController, curve: Curves.easeOutBack),
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

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final role = snap.data()?['role'];

    setState(() {
      _isPrivileged = role == 'Admin' || role == 'Club Head';
    });
  }

  Future<void> _loadAnnouncements() async {
    final snap = await _annRef.orderBy('date').get();

    final list = snap.docs.map((d) {
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

      return Announcement(
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
      );
    }).toList();

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

  List<Announcement> get _archived =>
      _announcements.where((a) => _archivedMap[a.id] == true).toList();

  int _indexOfAnnouncement(Announcement ann) {
    final list = _filtered;
    return list.indexWhere((a) => a.id == ann.id);
  }

  DateTime _combineAnnouncement(Announcement a) => DateTime(
    a.date.year,
    a.date.month,
    a.date.day,
    a.time.hour,
    a.time.minute,
  );

  Future<void> _loadAllVenueBookings() async {
    setState(() => _loadingBookings = true);
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
      final start = deadline;
      final end = DateTime(deadline.year, deadline.month, deadline.day, 23, 59);
      items.add(
        _VenueBooking(
          source: 'hackathon',
          title: data['name'] ?? 'Hackathon',
          venue: venue,
          from: start,
          to: end,
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
      final start = deadline;
      final end = DateTime(deadline.year, deadline.month, deadline.day, 23, 59);
      items.add(
        _VenueBooking(
          source: 'workshop',
          title: data['name'] ?? 'Workshop',
          venue: venue,
          from: start,
          to: end,
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
      final start = date;
      final end = DateTime(date.year, date.month, date.day, 23, 59);
      items.add(
        _VenueBooking(
          source: 'club',
          title: data['title'] ?? 'Club Event',
          venue: venue,
          from: start,
          to: end,
        ),
      );
    }

    items.sort((a, b) => a.from.compareTo(b.from));

    if (!mounted) return;
    setState(() {
      _allVenueBookings = items;
      _loadingBookings = false;
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
      if (b.venue.trim().toLowerCase() != venue.trim().toLowerCase()) {
        continue;
      }

      if (ignore != null && b.source == 'announcement') {
        final sameDate =
            b.from.year == ignore.date.year &&
            b.from.month == ignore.date.month &&
            b.from.day == ignore.date.day;
        final sameVenue =
            ignore.venue.trim().toLowerCase() == b.venue.trim().toLowerCase();
        if (sameDate && sameVenue) continue;
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
          b.from.day != date.day)
        continue;

      if (lastEnd == null || b.to.isAfter(lastEnd)) {
        lastEnd = b.to;
      }
    }

    if (lastEnd == null) return null;

    final dateStr = '${lastEnd.day}/${lastEnd.month}/${lastEnd.year}';
    final timeStr =
        '${lastEnd.hour.toString().padLeft(2, '0')}:${lastEnd.minute.toString().padLeft(2, '0')}';
    return '$venue is available after $dateStr $timeStr';
  }

  Map<String, int> _venueUsageCounts() {
    final Map<String, int> counts = {};
    for (final b in _allVenueBookings) {
      final key = b.venue.trim();
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
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
    String? errorMessage;
    String? venueNote;

    String? targetType = ann?.targetType;
    String? targetId = ann?.targetId;
    final targetIdCtrl = TextEditingController(text: targetId ?? '');

    String _resolveVenue() {
      if (selectedHall == null) return '';
      if (_fixedHalls.contains(selectedHall)) return selectedHall!;
      if (selectedHall == 'Other hall') {
        return otherHallCtrl.text.trim();
      }
      if (selectedHall == 'Room no') {
        final rn = roomNoCtrl.text.trim();
        return rn.isEmpty ? '' : 'Room $rn';
      }
      return '';
    }

    void validateVenue(StateSetter setDialogState) {
      final venueText = _resolveVenue();
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
      if (conflict) {
        venueNote =
            _availabilityNote(venue: venueText, date: date) ??
            '$venueText is not available for this date.';
      } else {
        venueNote = null;
      }
      setDialogState(() {});
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
                if (errorMessage != null) ...[
                  Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Text(
                  'Venue',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedHall,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on),
                    hintText: 'Select hall / room',
                  ),
                  items: [
                    ..._fixedHalls.map(
                      (h) => DropdownMenuItem(value: h, child: Text(h)),
                    ),
                    const DropdownMenuItem(
                      value: 'Other hall',
                      child: Text('Other hall'),
                    ),
                    const DropdownMenuItem(
                      value: 'Room no',
                      child: Text('Room number'),
                    ),
                  ],
                  onChanged: (v) {
                    final prev = selectedHall;
                    selectedHall = v;

                    if (v != 'Other hall') otherHallCtrl.clear();
                    if (v != 'Room no') roomNoCtrl.clear();

                    final venueText = _resolveVenue();
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

                    if (conflict) {
                      selectedHall = prev;
                      venueNote =
                          _availabilityNote(venue: venueText, date: date) ??
                          '$venueText is already booked for this date.';
                    } else {
                      venueNote = null;
                    }

                    setDialogState(() {});
                  },
                ),
                if (selectedHall == 'Other hall') ...[
                  const SizedBox(height: 4),
                  TextField(
                    controller: otherHallCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Enter other hall name',
                    ),
                    onChanged: (_) => validateVenue(setDialogState),
                  ),
                ],
                if (selectedHall == 'Room no') ...[
                  const SizedBox(height: 4),
                  TextField(
                    controller: roomNoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Enter room number',
                    ),
                    keyboardType: TextInputType.text,
                    onChanged: (_) => validateVenue(setDialogState),
                  ),
                ],
                if (venueNote != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    venueNote!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.redAccent,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text('Date: ${date.day}/${date.month}/${date.year}'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      date = picked;
                      validateVenue(setDialogState);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text('Time: ${time.format(context)}'),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: time,
                    );
                    if (picked != null) {
                      time = picked;
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
                  onChanged: (v) {
                    if (v != null) {
                      category = v;
                      setDialogState(() {});
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: targetType,
                  decoration: const InputDecoration(labelText: 'Link to'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('None')),
                    DropdownMenuItem(
                      value: 'hackathon',
                      child: Text('Hackathon'),
                    ),
                    DropdownMenuItem(
                      value: 'workshop',
                      child: Text('Workshop'),
                    ),
                    DropdownMenuItem(value: 'club', child: Text('Club Event')),
                  ],
                  onChanged: (v) {
                    targetType = v;
                    setDialogState(() {});
                  },
                ),
                TextField(
                  controller: targetIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Target ID (optional)',
                    helperText:
                        'Paste hackathon/workshop doc id or club event id',
                  ),
                  onChanged: (v) =>
                      targetId = v.trim().isEmpty ? null : v.trim(),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Mark as Important'),
                  value: important,
                  activeColor: Colors.red,
                  onChanged: (v) {
                    important = v;
                    setDialogState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text('Pin to top'),
                  value: pinned,
                  activeColor: Colors.teal,
                  onChanged: (v) {
                    pinned = v;
                    setDialogState(() {});
                  },
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
              child: const Text('Save'),
              onPressed: () async {
                validateVenue(setDialogState);
                final venueFinal = _resolveVenue();

                if (titleCtrl.text.isEmpty ||
                    descCtrl.text.isEmpty ||
                    venueFinal.isEmpty) {
                  setDialogState(
                    () => errorMessage = 'All fields are required!',
                  );
                  return;
                }
                if (venueNote != null) {
                  setDialogState(
                    () => errorMessage =
                        'Selected venue is currently not available for this date.',
                  );
                  return;
                }

                final user = FirebaseAuth.instance.currentUser;
                final editorName = user?.displayName ?? 'Unknown';

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
                  'updatedByName': editorName,
                };

                if (ann == null) {
                  final doc = await _annRef.add({
                    ...data,
                    'createdAt': FieldValue.serverTimestamp(),
                    'createdByName': editorName,
                  });

                  setState(() {
                    final now = DateTime.now();
                    _announcements.add(
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
                        targetType: targetType,
                        targetId: targetId,
                        createdByName: editorName,
                        updatedByName: editorName,
                        createdAt: now,
                        updatedAt: now,
                      ),
                    );
                  });
                } else {
                  await _annRef.doc(ann.id).set(data, SetOptions(merge: true));
                  setState(() {
                    final now = DateTime.now();
                    ann
                      ..title = data['title'] as String
                      ..description = data['description'] as String
                      ..venue = data['venue'] as String
                      ..date = date
                      ..time = time
                      ..category = category
                      ..isImportant = important
                      ..isPinned = pinned
                      ..targetType = targetType
                      ..targetId = targetId
                      ..updatedByName = editorName
                      ..updatedAt = now;
                    ann.createdByName ??= editorName;
                  });
                }

                await _loadAllVenueBookings();

                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteAnnouncement(Announcement ann) async {
    if (!_isPrivileged) return;
    await _annRef.doc(ann.id).delete();
    setState(() => _announcements.remove(ann));
    await _loadAllVenueBookings();
  }

  void _toggleArchive(Announcement ann) async {
    final current = _archivedMap[ann.id] == true;
    final newVal = !current;
    setState(() => _archivedMap[ann.id] = newVal);
    await _setAnnouncementState(ann, archived: newVal);
  }

  void _markAsRead(Announcement ann) async {
    if (_readMap[ann.id] == true) return;
    setState(() => _readMap[ann.id] = true);
    await _setAnnouncementState(ann, read: true);
  }

  bool _hasRelated(Announcement ann) => ann.targetType != null;

  void _openRelatedPage(Announcement ann) {
    if (ann.targetType == 'hackathon') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HackathonListPage()),
      );
    } else if (ann.targetType == 'workshop') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WorkshopListPage()),
      );
    } else if (ann.targetType == 'club') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ClubHubHomePage()),
      );
    }
  }

  void _openArchiveSheet() {
    final archived = _archived;
    if (archived.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No announcements in archive yet.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: archived.map((a) {
          return ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(a.title),
            subtitle: Text('${a.date.day}/${a.date.month}/${a.date.year}'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final idx = _indexOfAnnouncement(a);
                if (idx < 0) return;
                const itemExtent = 140.0;
                final offset = idx * itemExtent;
                _listScrollController.animateTo(
                  offset,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                );
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showVenueBookings() async {
    if (_loadingBookings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading venue bookings...')),
      );
      return;
    }
    if (_allVenueBookings.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Venue bookings'),
          content: const Text('No upcoming venue bookings found.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    final counts = _venueUsageCounts();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Venue bookings'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: counts.entries.map((e) {
                    final multi = e.value > 1 ? '  (multiple bookings!)' : '';
                    return Text(
                      '${e.key}: ${e.value} upcoming event(s)$multi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: e.value > 1 ? Colors.redAccent : Colors.black87,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _allVenueBookings.length,
                  itemBuilder: (_, i) {
                    final b = _allVenueBookings[i];
                    final dateStr =
                        '${b.from.day}/${b.from.month}/${b.from.year}';
                    final timeStr =
                        '${b.from.hour.toString().padLeft(2, '0')}:${b.from.minute.toString().padLeft(2, '0')}'
                        ' - '
                        '${b.to.hour.toString().padLeft(2, '0')}:${b.to.minute.toString().padLeft(2, '0')}';

                    return ListTile(
                      leading: const Icon(Icons.event_seat),
                      title: Text('${b.venue} (${b.source})'),
                      subtitle: Text('$dateStr • $timeStr\n${b.title}'),
                    );
                  },
                ),
              ),
            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loadingAnnouncements) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      drawer: _buildDrawer(isDark),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAnnouncements,
          ),
        ],
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
              'Announcements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
              ),
              onPressed: widget.onToggleTheme,
            ),
            if (_isPrivileged)
              IconButton(
                tooltip: 'Venue bookings',
                icon: const Icon(Icons.event_seat, color: Colors.white),
                onPressed: _showVenueBookings,
              ),
            Badge.count(
              count: _archived.length,
              isLabelVisible: _archived.isNotEmpty,
              alignment: Alignment.topRight,
              backgroundColor: Colors.deepPurple,
              textColor: Colors.white,
              child: IconButton(
                tooltip: 'Archived announcements',
                icon: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.white,
                ),
                onPressed: _openArchiveSheet,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: ScaleTransition(
              scale: _segScale,
              child: SegmentedButton<int>(
                style: ButtonStyle(
                  visualDensity: const VisualDensity(
                    horizontal: -1,
                    vertical: -1,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  side: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const BorderSide(color: Colors.teal, width: 1.2);
                    }
                    return const BorderSide(color: Colors.grey, width: 0.6);
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.teal.withOpacity(0.12);
                    }
                    return Theme.of(context).colorScheme.surface;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.teal.shade800;
                    }
                    return Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.8);
                  }),
                ),
                segments: const [
                  ButtonSegment(
                    value: 0,
                    icon: Icon(Icons.campaign_outlined, size: 18),
                    label: Text(
                      'Announcements',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.calendar_month_outlined, size: 18),
                    label: Text('Calendar', style: TextStyle(fontSize: 13)),
                  ),
                ],
                selected: {_currentIndex},
                onSelectionChanged: (set) {
                  setState(() => _currentIndex = set.first);
                  _segController
                    ..reset()
                    ..forward();
                },
              ),
            ),
          ),
          if (_currentIndex == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Expanded(flex: 6, child: _searchBar()),
                  const SizedBox(width: 6),
                  Expanded(flex: 4, child: _categoryDropdown()),
                ],
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _currentIndex == 0
                  ? Column(
                      key: const ValueKey('list'),
                      children: [
                        if (_isPrivileged) _buildAddAnnouncementHeader(),
                        _buildTopArchiveStrip(),
                        Expanded(
                          child: _filtered.isEmpty
                              ? const Center(
                                  child: Text('No announcements found'),
                                )
                              : ListView.builder(
                                  controller: _listScrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    8,
                                    12,
                                    80,
                                  ),
                                  itemCount: _filtered.length,
                                  itemBuilder: (_, i) =>
                                      _announcementCard(_filtered[i]),
                                ),
                        ),
                      ],
                    )
                  : Column(
                      key: const ValueKey('calendar'),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: const Text(
                            'Here you can view the announcement calendar – a clear snapshot of what is happening and when across your campus.',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        Expanded(
                          child: AnnouncementCalendarPage(
                            announcements: _announcements,
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

  Drawer _buildDrawer(bool isDark) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Eventra Menu',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.teal),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeScreen(
                    onToggleTheme: widget.onToggleTheme,
                    isDark: isDark,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bolt, color: Colors.teal),
            title: const Text('Hackathons'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HackathonListPage()),
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
                MaterialPageRoute(builder: (_) => const WorkshopListPage()),
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
                MaterialPageRoute(builder: (_) => const ClubHubHomePage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.purple),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ParticipantDashboard()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddAnnouncementHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.teal, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Add New Announcement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: _openForm,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopArchiveStrip() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.inventory_2_rounded,
            size: 18,
            color: Colors.deepPurple,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _archived.isEmpty
                  ? 'Tap the archive icon on any card to save it here for later.'
                  : 'You have ${_archived.length} announcement(s) preserved in your archive.',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: 34,
        child: TextField(
          decoration: const InputDecoration(
            icon: Icon(Icons.search, size: 18),
            hintText: 'Search...',
            border: InputBorder.none,
            isDense: true,
          ),
          onChanged: (v) => setState(() => _search = v),
        ),
      ),
    );
  }

  Widget _categoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AnnouncementCategory?>(
          value: _filterCategory,
          hint: const Text('Cat', style: TextStyle(fontSize: 12)),
          isExpanded: true,
          iconSize: 18,
          items: [
            const DropdownMenuItem<AnnouncementCategory?>(
              value: null,
              child: Text('All', style: TextStyle(fontSize: 12)),
            ),
            ...AnnouncementCategory.values.map(
              (c) => DropdownMenuItem<AnnouncementCategory?>(
                value: c,
                child: Text(
                  c.name.toUpperCase(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _filterCategory = v),
        ),
      ),
    );
  }

  void _showMetaInfo(Announcement ann) {
    final created = ann.createdAt;
    final updated = ann.updatedAt;
    final createdBy = ann.createdByName ?? 'Unknown';
    final updatedBy = ann.updatedByName ?? 'Unknown';

    String fmt(DateTime? dt) {
      if (dt == null) return 'N/A';
      return '${dt.day}/${dt.month}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Announcement info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Created by: $createdBy'),
            Text('Created at: ${fmt(created)}'),
            const SizedBox(height: 8),
            Text('Last edited by: $updatedBy'),
            Text('Last edited at: ${fmt(updated)}'),
          ],
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

  Widget _announcementCard(Announcement ann) {
    final isArchived = _archivedMap[ann.id] == true;
    final isRead = _readMap[ann.id] == true;
    final hasRelated = _hasRelated(ann);

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 400),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ExpansionTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                backgroundColor: ann.isImportant
                    ? Colors.red.withOpacity(0.15)
                    : Colors.blue.withOpacity(0.15),
                child: Icon(
                  ann.isImportant ? Icons.priority_high : Icons.campaign,
                  color: ann.isImportant ? Colors.red : Colors.blue,
                ),
              ),
              if (isArchived)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  ann.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isRead
                        ? Theme.of(
                            context,
                          ).textTheme.bodyMedium!.color!.withOpacity(0.6)
                        : Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                tooltip: 'View info',
                onPressed: () => _showMetaInfo(ann),
              ),
            ],
          ),
          subtitle: Text(ann.category.name.toUpperCase()),
          trailing: _isPrivileged
              ? IconButton(
                  icon: Icon(
                    ann.isImportant ? Icons.star : Icons.star_border,
                    color: ann.isImportant ? Colors.orange : null,
                  ),
                  onPressed: () {
                    setState(() {
                      ann.isImportant = !ann.isImportant;
                    });
                  },
                )
              : null,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ann.venue.isNotEmpty)
                    Text(
                      'Venue: ${ann.venue}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  Text(
                    'Date: ${ann.date.day}/${ann.date.month}/${ann.date.year}',
                  ),
                  Text('Time: ${ann.time.format(context)}'),
                  const SizedBox(height: 8),
                  Text(ann.description),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                children: [
                  TextButton.icon(
                    icon: Icon(
                      isArchived
                          ? Icons.check_circle
                          : Icons.inventory_2_outlined,
                      size: 18,
                      color: isArchived ? Colors.deepPurple : null,
                    ),
                    label: Text(
                      isArchived ? 'Added to archive' : 'Add to archive',
                    ),
                    onPressed: () => _toggleArchive(ann),
                  ),
                  if (hasRelated)
                    TextButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open'),
                      onPressed: () => _openRelatedPage(ann),
                    ),
                  if (!_isPrivileged)
                    TextButton.icon(
                      icon: Icon(
                        isRead
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                      ),
                      label: Text(isRead ? 'Marked as read' : 'Mark as read'),
                      onPressed: isRead ? null : () => _markAsRead(ann),
                    ),
                  if (_isPrivileged) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: () => _openForm(ann: ann),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () => _deleteAnnouncement(ann),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VenueBooking {
  final String source;
  final String title;
  final String venue;
  final DateTime from;
  final DateTime to;

  _VenueBooking({
    required this.source,
    required this.title,
    required this.venue,
    required this.from,
    required this.to,
  });
}
