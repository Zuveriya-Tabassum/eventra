import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DailyContestService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static String todayKey() =>
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// ✅ Check if THIS USER already played today
  static Future<bool> hasPlayedToday() async {
    final user = _auth.currentUser!;
    final snap = await _db
        .collection('users')
        .doc(user.uid)
        .collection('daily_contest')
        .doc(todayKey())
        .get();

    return snap.exists && (snap.data()?['played'] == true);
  }

  /// ✅ Mark played ONCE after contest finishes
  static Future<void> markPlayed(int totalScore) async {
    final user = _auth.currentUser!;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('daily_contest')
        .doc(todayKey())
        .set({
      'played': true,
      'totalScore': totalScore,
      'playedAt': FieldValue.serverTimestamp(),
    });
  }
}