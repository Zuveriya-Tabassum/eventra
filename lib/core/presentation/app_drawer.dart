import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/dashboard/streak_dashboard.dart';
import '../../features/events/hackathon_list.dart';
import '../../features/events/workshop_list.dart';
import '../../features/clubs/club.dart';
import '../../features/events/fests_list.dart';
import '../../features/contests/daily_contest.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex; // 0: Ann, 1: Home, 2: Profile
  final Function(int)? onTabSelected;

  const AppDrawer({super.key, this.currentIndex = 1, this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          _buildHeader(user),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildItem(
                  context,
                  icon: Icons.home_filled,
                  label: 'Home',
                  selected: currentIndex == 1,
                  onTap: () => _handleNav(context, 1, '/home'),
                ),
                _buildItem(
                  context,
                  icon: Icons.campaign_rounded,
                  label: 'Announcements',
                  selected: currentIndex == 0,
                  onTap: () => _handleNav(context, 0, '/announcements'),
                ),
                const Divider(indent: 16, endIndent: 16),
                _buildSectionHeader('Activities'),
                _buildItem(
                  context,
                  icon: Icons.bolt,
                  label: 'Hackathons',
                  onTap: () => _push(context, const HackathonListPage()),
                ),
                _buildItem(
                  context,
                  icon: Icons.school_rounded,
                  label: 'Workshops',
                  onTap: () => _push(context, const WorkshopListPage()),
                ),
                _buildItem(
                  context,
                  icon: Icons.groups_rounded,
                  label: 'Club Hub',
                  onTap: () => _push(context, const ClubHubHomePage()),
                ),
                _buildItem(
                  context,
                  icon: Icons.event_note_rounded,
                  label: 'Fests & Events',
                  onTap: () => _push(context, const FestsListPage()),
                ),
                _buildItem(
                  context,
                  icon: Icons.quiz_rounded,
                  label: 'Daily Contest',
                  onTap: () => _push(context, const DailyContestPage()),
                ),
                const Divider(indent: 16, endIndent: 16),
                _buildSectionHeader('Personal'),
                _buildItem(
                  context,
                  icon: Icons.person_rounded,
                  label: 'My Profile',
                  selected: currentIndex == 2,
                  onTap: () => _handleNav(context, 2, '/participant'),
                ),
                _buildItem(
                  context,
                  icon: Icons.local_fire_department_rounded,
                  label: 'Streak Dashboard',
                  iconColor: Colors.orange,
                  onTap: () {
                    if (user != null) {
                      _push(context, StreakDashboard(userId: user.uid));
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildItem(
            context,
            icon: Icons.logout_rounded,
            label: 'Logout',
            iconColor: Colors.redAccent,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (r) => false,
                );
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String name = 'Eventra User';
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? name;
          photoUrl = data['profileImage'];
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null
                    ? Icon(
                        Icons.person,
                        size: 36,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                user?.email ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
    Color? iconColor,
  }) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        onTap: onTap,
        dense: true,
        selected: selected,
        selectedTileColor: Theme.of(
          context,
        ).colorScheme.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: iconColor ?? color, size: 22),
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _handleNav(BuildContext context, int tabIndex, String routeName) {
    Navigator.pop(context);
    if (onTabSelected != null) {
      onTabSelected!(tabIndex);
    } else {
      Navigator.pushNamed(context, routeName);
    }
  }

  void _push(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
