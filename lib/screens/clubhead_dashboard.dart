// lib/screens/clubhead_dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClubHeadDashboard extends StatelessWidget {
  const ClubHeadDashboard({super.key});

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Club‑Head Dashboard'),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (_) => false);
            }
          },
        )
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hello, ${_user?.email ?? 'Club‑Head'}!',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 30),

          // ── Create‑Event placeholder ──
          ElevatedButton.icon(
            icon: const Icon(Icons.event_available),
            label: const Text('Create New Event'),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('TODO: open create‑event screen')));
            },
          ),

          const SizedBox(height: 40),
          const Text(
              'Here you can manage your club’s events. '
                  'Coming features:\n'
                  ' • Create / edit events\n'
                  ' • View registrations\n'
                  ' • Send notifications\n',
              style: TextStyle(fontSize: 16)),
        ],
      ),
    ),
  );
}
