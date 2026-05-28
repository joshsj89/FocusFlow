import 'package:cloud_firestore/cloud_firestore.dart';

enum MoodRating { great, alright, notSoWell, bad }

extension MoodRatingX on MoodRating {
  // Maps to the Firestore string values defined in the spec
  String toValue() => switch (this) {
        MoodRating.great => 'great',
        MoodRating.alright => 'alright',
        MoodRating.notSoWell => 'notSoWell',
        MoodRating.bad => 'bad',
      };
}

class SessionRecord {
  final String id;
  final String userId;
  final String timerProfileId;
  final int focusDurationSeconds;
  final int completedSessions;
  final MoodRating? mood;
  final DateTime completedAt;

  const SessionRecord({
    required this.id,
    required this.userId,
    required this.timerProfileId,
    required this.focusDurationSeconds,
    required this.completedSessions,
    this.mood,
    required this.completedAt,
  });

  factory SessionRecord.fromMap(Map<String, dynamic> map, {String? id}) {
    return SessionRecord(
      id: id ?? map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      timerProfileId: map['timerProfileId'] as String? ?? '',
      focusDurationSeconds: map['focusDurationSeconds'] as int? ?? 0,
      completedSessions: map['completedSessions'] as int? ?? 0,
      mood: _moodFromValue(map['mood'] as String?),
      completedAt: (map['completedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'timerProfileId': timerProfileId,
        'focusDurationSeconds': focusDurationSeconds,
        'completedSessions': completedSessions,
        'mood': mood?.toValue(),
        'completedAt': Timestamp.fromDate(completedAt),
      };

  SessionRecord copyWith({
    String? timerProfileId,
    int? focusDurationSeconds,
    int? completedSessions,
    MoodRating? mood,
    DateTime? completedAt,
  }) {
    return SessionRecord(
      id: id,
      userId: userId,
      timerProfileId: timerProfileId ?? this.timerProfileId,
      focusDurationSeconds: focusDurationSeconds ?? this.focusDurationSeconds,
      completedSessions: completedSessions ?? this.completedSessions,
      mood: mood ?? this.mood,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  static MoodRating? _moodFromValue(String? value) =>
      value == null ? null : MoodRating.values.where((e) => e.toValue() == value).firstOrNull;
}
