import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timer_model.dart';

class TimerService {
  static CollectionReference<Map<String, dynamic>> _ref(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('timers');

  static Stream<List<TimerModel>> watchTimers(String uid) {
    return _ref(uid)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(TimerModel.fromFirestore).toList());
  }

  static Future<void> addTimer(
    String uid, {
    required String name,
    required int durationMins,
    required int sessions,
  }) {
    return _ref(uid).add({
      'name': name,
      'durationMins': durationMins,
      'sessions': sessions,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<void> updateTimer(String uid, TimerModel timer) {
    return _ref(uid).doc(timer.id).update({
      'name': timer.name,
      'durationMins': timer.durationMins,
      'sessions': timer.sessions,
    });
  }

  static Future<void> deleteTimer(String uid, String timerId) {
    return _ref(uid).doc(timerId).delete();
  }
}
