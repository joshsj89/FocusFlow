import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timer_profile.dart';

class TimerService {
  static DocumentReference<Map<String, dynamic>> _ref(String uid) =>
      FirebaseFirestore.instance.collection('timers').doc(uid);

  static Stream<List<TimerProfile>> watchTimers(String uid) {
    return _ref(uid).snapshots().map((doc) {
      if (!doc.exists) return [];
      final list = (doc.data()?['timers'] as List<dynamic>?) ?? [];
      return list
          .map((e) => TimerProfile.fromMap(e as Map<String, dynamic>))
          .toList();
    });
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
    final ref = _ref(uid);
    final doc = await ref.get();
    final timers = _parseTimers(doc);
    final newTimer = TimerProfile(
      id: FirebaseFirestore.instance.collection('_').doc().id,
      userId: uid,
      name: name,
      activityType: activityType,
      focusDuration: focusDuration,
      breakDuration: breakDuration,
      sessionsPerSit: sessionsPerSit,
      soundscapeId: soundscapeId,
      createdAt: DateTime.now(),
    );
    timers.add(newTimer);
    await ref.set({'timers': timers.map((t) => t.toMap()).toList()});
  }

  static Future<void> updateTimer(String uid, TimerProfile timer) async {
    final ref = _ref(uid);
    final doc = await ref.get();
    final timers = _parseTimers(doc);
    final index = timers.indexWhere((t) => t.id == timer.id);
    if (index == -1) return;
    timers[index] = timer;
    await ref.set({'timers': timers.map((t) => t.toMap()).toList()});
  }

  static Future<void> deleteTimer(String uid, String timerId) async {
    final ref = _ref(uid);
    final doc = await ref.get();
    final timers = _parseTimers(doc)..removeWhere((t) => t.id == timerId);
    await ref.set({'timers': timers.map((t) => t.toMap()).toList()});
  }

  static List<TimerProfile> _parseTimers(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) return [];
    final list = (doc.data()?['timers'] as List<dynamic>?) ?? [];
    return list
        .map((e) => TimerProfile.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
