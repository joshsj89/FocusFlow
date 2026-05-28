import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timer_profile.dart';

class TimerService {
  static CollectionReference<Map<String, dynamic>> _timersCol(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('timers');

  static Stream<List<TimerProfile>> watchTimers(String uid) {
    return _timersCol(uid)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TimerProfile.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  static Future<void> addTimer(
    String uid, {
    required String name,
    required int focusDuration,
    required int sessionsPerSit,
    String activityType = 'studying',
    int breakDuration = 300,
    String soundscapeId = 'ambient_rain',
  }) async {
    final profile = TimerProfile(
      id: '',
      userId: uid,
      name: name,
      activityType: activityType,
      focusDuration: focusDuration,
      breakDuration: breakDuration,
      sessionsPerSit: sessionsPerSit,
      soundscapeId: soundscapeId,
      createdAt: DateTime.now(),
    );
    await _timersCol(uid).add(profile.toMap());
  }

  static Future<void> updateTimer(String uid, TimerProfile timer) async {
    await _timersCol(uid).doc(timer.id).update(timer.toMap());
  }

  static Future<void> deleteTimer(String uid, String timerId) async {
    await _timersCol(uid).doc(timerId).delete();
  }
}
