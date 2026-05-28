class StreakData {
  final int currentStreak;
  final int longestStreak;
  // Dates normalized to midnight local time — use DateTime(y, m, d) when inserting
  final Set<DateTime> activeDays;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.activeDays,
  });

  factory StreakData.empty() => const StreakData(
        currentStreak: 0,
        longestStreak: 0,
        activeDays: {},
      );

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    Set<DateTime>? activeDays,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      activeDays: activeDays ?? this.activeDays,
    );
  }
}
