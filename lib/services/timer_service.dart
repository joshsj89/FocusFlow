import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timer_model.dart';

class TimerService {
  static DocumentReference<Map<String, dynamic>> _ref(String uid) =>
      FirebaseFirestore.instance.collection('timers').doc(uid);

  static Stream<List<TimerModel>> watchTimers(String uid) {
    return _ref(uid).snapshots().map((doc) {
      if (!doc.exists) return [];
      final list = (doc.data()?['timers'] as List<dynamic>?) ?? [];
      return list
          .map((e) => TimerModel.fromMap(e as Map<String, dynamic>))
          .toList();
    });
  }

  static Future<void> addTimer(
    String uid, {
    required String name,
    required int durationMins,
    required int sessions,
  }) async {
    final ref = _ref(uid);
    final doc = await ref.get();
    final timers = _parseTimers(doc);
    timers.add(TimerModel(
      id: FirebaseFirestore.instance.collection('_').doc().id,
      name: name,
      durationMins: durationMins,
      sessions: sessions,
      createdAt: DateTime.now(),
    ));
    await ref.set({'timers': timers.map((t) => t.toMap()).toList()});
  }

  static Future<void> updateTimer(String uid, TimerModel timer) async {
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

  static List<TimerModel> _parseTimers(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) return [];
    final list = (doc.data()?['timers'] as List<dynamic>?) ?? [];
    return list
        .map((e) => TimerModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
