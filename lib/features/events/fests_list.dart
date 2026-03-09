// lib/features/events/fests_list.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'event_registration_form.dart';
import '../../core/presentation/app_drawer.dart';

class FestsListPage extends StatefulWidget {
  const FestsListPage({super.key});

  @override
  State<FestsListPage> createState() => _FestsListPageState();
}

class _FestsListPageState extends State<FestsListPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<ClubEvent> clubEvents = [];
  String? _role;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _role = snap.data()?['role'] as String? ?? 'Participant';
        });
      }
    }

    // Load events from Firestore (assuming a collection 'fests' or using the list below as base)
    // For now, using the provided mock data but standardizing it
    clubEvents.addAll([
      ClubEvent(
        id: 'e1',
        createdBy: 'system',
        lastEditedBy: 'system',
        lastEditedAt: DateTime.now(),
        logoPath: 'assets/images/eventra_logo.png',
        name: 'Robotics Challenge',
        description: 'Compete with your robotics creations!\nTeams battle in fun tasks to test design and programming skills.',
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
        logoPath: 'assets/images/eventra_logo.png',
        name: 'Photography Marathon',
        description: 'Capture the beauty around the campus in 12 hours.\nSubmit your best shots to win exciting prizes.',
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
    ]);

    if (mounted) setState(() => _loading = false);
  }

  bool get _isAdmin => _role == 'Admin';

  List<ClubEvent> getUpcoming() {
    final now = DateTime.now();
    return clubEvents.where((e) => e.deadline.isAfter(now.add(const Duration(hours: 24)))).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Fests & Events'),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildEventList(getUpcoming()),
              _buildEventList(getOngoing()),
              _buildEventList(getCompleted()),
            ],
          ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: Theme.of(context).colorScheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Event', style: TextStyle(color: Colors.white)),
              onPressed: () {}, // Implementation depends on Firestore structure
            )
          : null,
    );
  }

  Widget _buildEventList(List<ClubEvent> list) {
    return list.isEmpty
        ? Center(child: Text('No events found.', style: TextStyle(color: Colors.grey.shade600)))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) => ClubEventCard(
              event: list[index],
              isAdmin: _isAdmin,
            ),
          );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class ClubEvent {
  final String id, createdBy, lastEditedBy, logoPath, name, description, venue, organizer, prerequisites, backgroundImage, contactName, contactPhone, contactEmail;
  final DateTime lastEditedAt, deadline;
  final bool paymentRequired;

  ClubEvent({
    required this.id, required this.createdBy, required this.lastEditedBy, required this.lastEditedAt,
    required this.logoPath, required this.name, required this.description, required this.venue,
    required this.deadline, required this.organizer, required this.prerequisites, required this.backgroundImage,
    required this.contactName, required this.contactPhone, required this.contactEmail, required this.paymentRequired,
  });
}

class ClubEventCard extends StatefulWidget {
  final ClubEvent event;
  final bool isAdmin;

  const ClubEventCard({super.key, required this.event, required this.isAdmin});

  @override
  State<ClubEventCard> createState() => _ClubEventCardState();
}

class _ClubEventCardState extends State<ClubEventCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Text(e.name[0], style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        ),
        title: Text(e.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(e.venue, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(DateFormat('MMM dd, yyyy').format(e.deadline), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Text(e.description, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
                const SizedBox(height: 16),
                _infoRow(Icons.groups_outlined, 'Organized by', e.organizer),
                _infoRow(Icons.assignment_outlined, 'Prerequisites', e.prerequisites),
                _infoRow(Icons.contact_phone_outlined, 'Contact', '${e.contactName} (${e.contactPhone})'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.isAdmin) IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.grey), onPressed: () {}),
                    if (widget.isAdmin) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () {}),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (e.paymentRequired) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ClubRegistrationFormPage(eventName: e.name)));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(e.paymentRequired ? 'Enroll Now' : 'Mark as Read'),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87, fontFamily: 'Inter'),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
