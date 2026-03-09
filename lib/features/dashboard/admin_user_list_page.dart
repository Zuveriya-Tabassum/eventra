import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum UserFilterType { all, participants, clubHeads, pending }

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
      case UserFilterType.pending:
        return 'Pending Approvals';
      case UserFilterType.all:
        return 'All Users';
    }
  }

  Future<void> _approveUser(BuildContext context, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'status': 'approved',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User approved successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
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
            final status = (data['status'] ?? 'approved') as String;

            if (filterType == UserFilterType.pending) {
              return status == 'pending';
            }
            
            // For other filters, we usually show approved users, 
            // but for 'all' we might want to show everything or just approved.
            // Let's show everything in 'all' but filter by role in others.
            
            if (filterType == UserFilterType.participants) {
              return role == 'Participant' && status == 'approved';
            }
            if (filterType == UserFilterType.clubHeads) {
              return role == 'Club Head' && status == 'approved';
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
              final status = (data['status'] ?? 'approved') as String;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: status == 'pending' ? Colors.orange.shade100 : Colors.teal.shade100,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: status == 'pending' ? Colors.orange : Colors.teal,
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
                  trailing: status == 'pending' 
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(60, 30),
                        ),
                        onPressed: () => _approveUser(context, doc.id),
                        child: const Text('Approve', style: TextStyle(fontSize: 12)),
                      )
                    : Column(
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
