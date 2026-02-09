import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum UserFilterType { all, participants, clubHeads }

class AdminUserListPage extends StatelessWidget {
  const AdminUserListPage({
    super.key,
    required this.filterType,
  });

  final UserFilterType filterType;

  String get _title {
    switch (filterType) {
      case UserFilterType.participants:
        return 'Participants';
      case UserFilterType.clubHeads:
        return 'Club Heads';
      case UserFilterType.all:
        return 'All Users';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final role = (data['role'] ?? 'Participant') as String;
            if (filterType == UserFilterType.participants) {
              return role == 'Participant';
            }
            if (filterType == UserFilterType.clubHeads) {
              return role == 'Club Head';
            }
            return true;
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text('No users found', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? 'User') as String;
              final email = (data['email'] ?? '') as String;
              final role = (data['role'] ?? 'Participant') as String;
              final streak = (data['streak'] ?? 0) as int;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '$role • $email',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_fire_department,
                          size: 16, color: Colors.deepOrange),
                      Text(
                        '$streak',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
