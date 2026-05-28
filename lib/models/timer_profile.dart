import 'package:cloud_firestore/cloud_firestore.dart';

class TimerProfile {
  final String id;
  final String userId;
  final String name;
  final String activityType; // "studying"|"coding"|"reading"|"exercise"|"research"|"other"
  final int focusDuration;   // seconds
  final int breakDuration;   // seconds
  final int sessionsPerSit;
  final String soundscapeId;
  final DateTime createdAt;

  const TimerProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.activityType,
    required this.focusDuration,
    required this.breakDuration,
    required this.sessionsPerSit,
    required this.soundscapeId,
    required this.createdAt,
  });

  factory TimerProfile.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawCreatedAt = map['createdAt'];
    return TimerProfile(
      id: id ?? map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String,
      activityType: map['activityType'] as String? ?? 'studying',
      focusDuration: map['focusDuration'] as int? ?? 1500,
      breakDuration: map['breakDuration'] as int? ?? 300,
      sessionsPerSit: map['sessionsPerSit'] as int? ?? 4,
      soundscapeId: map['soundscapeId'] as String? ?? 'ambient_rain',
      createdAt: rawCreatedAt is Timestamp
          ? rawCreatedAt.toDate()
          : rawCreatedAt is String
              ? DateTime.parse(rawCreatedAt)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'activityType': activityType,
        'focusDuration': focusDuration,
        'breakDuration': breakDuration,
        'sessionsPerSit': sessionsPerSit,
        'soundscapeId': soundscapeId,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  TimerProfile copyWith({
    String? name,
    String? activityType,
    int? focusDuration,
    int? breakDuration,
    int? sessionsPerSit,
    String? soundscapeId,
  }) {
    return TimerProfile(
      id: id,
      userId: userId,
      name: name ?? this.name,
      activityType: activityType ?? this.activityType,
      focusDuration: focusDuration ?? this.focusDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      sessionsPerSit: sessionsPerSit ?? this.sessionsPerSit,
      soundscapeId: soundscapeId ?? this.soundscapeId,
      createdAt: createdAt,
    );
  }
}
