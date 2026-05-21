import 'session_record.dart';

class WeeklyWellnessSummary {
  final int totalSessions;
  final double totalHours;
  final double completionRate; // 0.0–1.0
  final double avgMoodScore;   // 1.0–4.0 (great=4, alright=3, notSoWell=2, bad=1)
  final DateTime weekStart;
  final DateTime weekEnd;

  const WeeklyWellnessSummary({
    required this.totalSessions,
    required this.totalHours,
    required this.completionRate,
    required this.avgMoodScore,
    required this.weekStart,
    required this.weekEnd,
  });

  factory WeeklyWellnessSummary.empty(DateTime weekStart, DateTime weekEnd) {
    return WeeklyWellnessSummary(
      totalSessions: 0,
      totalHours: 0,
      completionRate: 0,
      avgMoodScore: 0,
      weekStart: weekStart,
      weekEnd: weekEnd,
    );
  }

  // Computed client-side from a list of SessionRecords — not persisted to Firestore
  factory WeeklyWellnessSummary.fromSessions(
    List<SessionRecord> sessions,
    DateTime weekStart,
    DateTime weekEnd,
  ) {
    if (sessions.isEmpty) {
      return WeeklyWellnessSummary.empty(weekStart, weekEnd);
    }

    final totalSessions = sessions.length;
    final totalSeconds =
        sessions.fold<int>(0, (sum, s) => sum + s.focusDurationSeconds);
    final totalHours = totalSeconds / 3600;

    final sessionsWithMood = sessions.where((s) => s.mood != null).toList();
    final avgMoodScore = sessionsWithMood.isEmpty
        ? 0.0
        : sessionsWithMood.fold<double>(
                0, (sum, s) => sum + _moodScore(s.mood!)) /
            sessionsWithMood.length;

    // completionRate: sessions with a mood recorded vs total
    final completionRate = totalSessions == 0
        ? 0.0
        : sessionsWithMood.length / totalSessions;

    return WeeklyWellnessSummary(
      totalSessions: totalSessions,
      totalHours: double.parse(totalHours.toStringAsFixed(1)),
      completionRate: double.parse(completionRate.toStringAsFixed(2)),
      avgMoodScore: double.parse(avgMoodScore.toStringAsFixed(1)),
      weekStart: weekStart,
      weekEnd: weekEnd,
    );
  }

  static double _moodScore(MoodRating mood) => switch (mood) {
        MoodRating.great => 4.0,
        MoodRating.alright => 3.0,
        MoodRating.notSoWell => 2.0,
        MoodRating.bad => 1.0,
      };
}
