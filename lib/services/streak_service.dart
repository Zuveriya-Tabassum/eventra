import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StreakService {
  static final CollectionReference users =
  FirebaseFirestore.instance.collection('users');

  /// Call once per day (e.g. app open / successful login)
  static Future<void> updateDailyStreak(String userId) async {
    final userRef = users.doc(userId);

    // Use local calendar date only (00:00 – 23:59)
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final String todayKey = DateFormat('yyyy-MM-dd').format(today);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snap = await transaction.get(userRef);
      final data = snap.data() as Map<String, dynamic>? ?? {};

      int streak = (data['streak'] ?? 0) as int;
      String? lastVisitStr = data['lastVisitDate'];

      DateTime? lastVisitDate;
      if (lastVisitStr != null && lastVisitStr.isNotEmpty) {
        lastVisitDate = DateTime.parse(lastVisitStr);
      }

      if (lastVisitDate == null) {
        // First login ever
        streak = 1;
      } else {
        final DateTime lastDate = DateTime(
          lastVisitDate.year,
          lastVisitDate.month,
          lastVisitDate.day,
        );

        final int diffDays = today.difference(lastDate).inDays;

        if (diffDays == 0) {
          // Same day → do nothing
          return;
        } else if (diffDays == 1) {
          // Consecutive day
          streak += 1;
        } else {
          // Missed one or more days → reset
          streak = 0;
        }
      }

      // Update user document
      transaction.update(userRef, {
        'streak': streak,
        'lastVisitDate': todayKey,
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // One document per day in login_history
      final loginHistoryRef =
      userRef.collection('login_history').doc(todayKey);

      transaction.set(
        loginHistoryRef,
        {'loggedInAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    });
  }
}
