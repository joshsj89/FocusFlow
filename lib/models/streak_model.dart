class StreakModel {
  final Set<String> activeDays; // stored as 'YYYY-MM-DD'

  const StreakModel({required this.activeDays});

  static StreakModel empty() => StreakModel(activeDays: {});

  /// Day-of-month numbers that have activity in the given month.
  Set<int> activeDaysInMonth(int year, int month) {
    final prefix = '$year-${month.toString().padLeft(2, '0')}-';
    return activeDays
        .where((d) => d.startsWith(prefix))
        .map((d) => int.parse(d.substring(8)))
        .toSet();
  }

  /// Consecutive days ending today (or yesterday if today not yet recorded).
  int get currentStreak {
    if (activeDays.isEmpty) return 0;
    var check = DateTime.now();
    if (!activeDays.contains(fmt(check))) {
      check = check.subtract(const Duration(days: 1));
    }
    var count = 0;
    while (activeDays.contains(fmt(check))) {
      count++;
      check = check.subtract(const Duration(days: 1));
    }
    return count;
  }

  static String fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String today() => fmt(DateTime.now());
}
