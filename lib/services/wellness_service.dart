import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wellness_model.dart';

class WellnessService {
  static DocumentReference<Map<String, dynamic>> _ref(String uid) =>
      FirebaseFirestore.instance.collection('wellness').doc(uid);

  static Stream<WeeklyWellnessStats> watchWeeklyStats(String uid) {
    return _ref(uid).snapshots().map((doc) {
      final list = (doc.data()?['entries'] as List<dynamic>?) ?? [];
      final all = list
          .map((e) => WellnessEntry.fromMap(e as Map<String, dynamic>))
          .toList();
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final week = all.where((e) => e.timestamp.isAfter(weekAgo)).toList();
      return WeeklyWellnessStats.fromEntries(week);
    });
  }

  static Future<void> recordEntry(
    String uid, {
    required Mood? mood,
    required int focusMins,
    required int sessionsCompleted,
  }) async {
    final ref = _ref(uid);
    final doc = await ref.get();
    final entries = ((doc.data()?['entries'] as List<dynamic>?) ?? [])
        .cast<Map<String, dynamic>>()
        .toList();
    entries.add(WellnessEntry(
      timestamp: DateTime.now(),
      mood: mood,
      focusMins: focusMins,
      sessionsCompleted: sessionsCompleted,
    ).toMap());
    await ref.set({'entries': entries});
  }
}
