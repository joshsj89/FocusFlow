import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/streak_model.dart';

class StreakService {
  static DocumentReference<Map<String, dynamic>> _ref(String uid) =>
      FirebaseFirestore.instance.collection('streaks').doc(uid);

  static Stream<StreakModel> watchStreaks(String uid) {
    return _ref(uid).snapshots().map((doc) {
      final list = (doc.data()?['activeDays'] as List<dynamic>?) ?? [];
      return StreakModel(activeDays: list.cast<String>().toSet());
    });
  }

  /// Adds today's date to the user's active days (idempotent).
  static Future<void> recordToday(String uid) async {
    final today = StreakModel.today();
    final ref = _ref(uid);
    final doc = await ref.get();
    final days = ((doc.data()?['activeDays'] as List<dynamic>?) ?? [])
        .cast<String>()
        .toSet();
    if (days.contains(today)) return;
    days.add(today);
    await ref.set({'activeDays': days.toList()});
  }
}
