import 'dart:ui' show Color;

enum Mood { great, alright, notWell, bad }

extension MoodExtension on Mood {
  int get score => switch (this) {
        Mood.great => 4,
        Mood.alright => 3,
        Mood.notWell => 2,
        Mood.bad => 1,
      };

  String get label => switch (this) {
        Mood.great => 'Great!',
        Mood.alright => 'Alright.',
        Mood.notWell => 'Not too well..',
        Mood.bad => 'Bad.',
      };

  Color get color => switch (this) {
        Mood.great => const Color(0xFF4CAF50),
        Mood.alright => const Color(0xFFFFCA28),
        Mood.notWell => const Color(0xFFFF7043),
        Mood.bad => const Color(0xFFE91E63),
      };
}

// ---------------------------------------------------------------------------

class WellnessEntry {
  final DateTime timestamp;
  final Mood? mood;
  final int focusMins;
  final int sessionsCompleted;

  const WellnessEntry({
    required this.timestamp,
    required this.mood,
    required this.focusMins,
    required this.sessionsCompleted,
  });

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp.toUtc().toIso8601String(),
        'mood': mood?.name,
        'focusMins': focusMins,
        'sessionsCompleted': sessionsCompleted,
      };

  factory WellnessEntry.fromMap(Map<String, dynamic> map) {
    final moodStr = map['mood'] as String?;
    return WellnessEntry(
      timestamp: DateTime.parse(map['timestamp'] as String).toLocal(),
      mood: moodStr != null
          ? Mood.values.firstWhere((m) => m.name == moodStr,
              orElse: () => Mood.alright)
          : null,
      focusMins: (map['focusMins'] as num?)?.toInt() ?? 0,
      sessionsCompleted: (map['sessionsCompleted'] as num?)?.toInt() ?? 0,
    );
  }
}

// ---------------------------------------------------------------------------

class WeeklyWellnessStats {
  final double hoursFocused;
  final int sessionsCompleted;
  final int completionPct; // % of last 7 days with at least one session
  final double? avgMoodScore; // 1.0–4.0, null when no moods recorded

  const WeeklyWellnessStats({
    required this.hoursFocused,
    required this.sessionsCompleted,
    required this.completionPct,
    required this.avgMoodScore,
  });

  static WeeklyWellnessStats empty() => const WeeklyWellnessStats(
        hoursFocused: 0,
        sessionsCompleted: 0,
        completionPct: 0,
        avgMoodScore: null,
      );

  static WeeklyWellnessStats fromEntries(List<WellnessEntry> entries) {
    if (entries.isEmpty) return empty();

    final totalMins = entries.fold(0, (s, e) => s + e.focusMins);
    final totalSessions = entries.fold(0, (s, e) => s + e.sessionsCompleted);

    final activeDays = entries
        .map((e) =>
            '${e.timestamp.year}-${e.timestamp.month}-${e.timestamp.day}')
        .toSet();
    final completionPct = ((activeDays.length / 7) * 100).round().clamp(0, 100);

    final moodEntries = entries.where((e) => e.mood != null).toList();
    double? avgMood;
    if (moodEntries.isNotEmpty) {
      avgMood = moodEntries.fold(0.0, (s, e) => s + e.mood!.score) /
          moodEntries.length;
    }

    return WeeklyWellnessStats(
      hoursFocused: totalMins / 60,
      sessionsCompleted: totalSessions,
      completionPct: completionPct,
      avgMoodScore: avgMood,
    );
  }

  /// Maps the average mood score to the nearest mood color.
  Color? get avgMoodColor {
    if (avgMoodScore == null) return null;
    if (avgMoodScore! >= 3.5) return Mood.great.color;
    if (avgMoodScore! >= 2.5) return Mood.alright.color;
    if (avgMoodScore! >= 1.5) return Mood.notWell.color;
    return Mood.bad.color;
  }
}
