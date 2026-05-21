import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants/badge_definitions.dart';
import '../models/badge.dart';
import '../models/streak_data.dart';

// ── States ────────────────────────────────────────────────────────────────────

abstract class StreakState extends Equatable {
  const StreakState();
  @override
  List<Object?> get props => [];
}

class StreakLoading extends StreakState {
  const StreakLoading();
}

class StreakLoaded extends StreakState {
  final StreakData streakData;
  final List<Badge> badges;

  const StreakLoaded({required this.streakData, required this.badges});

  @override
  List<Object?> get props => [streakData, badges];
}

class StreakError extends StreakState {
  final String message;
  const StreakError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class StreakCubit extends Cubit<StreakState> {
  StreakCubit() : super(const StreakLoading());

  static DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  Future<void> loadStreaks() async {
    emit(const StreakLoading());
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        emit(const StreakError('Not authenticated'));
        return;
      }

      final results = await Future.wait([
        _userDoc(uid).collection('sessions').get(),
        _userDoc(uid).collection('badges').get(),
      ]);

      final sessionSnap = results[0];
      final badgeSnap = results[1];

      final activeDays = sessionSnap.docs
          .map((doc) {
            final raw = doc.data()['completedAt'];
            if (raw is! Timestamp) return null;
            final dt = raw.toDate().toLocal();
            return DateTime(dt.year, dt.month, dt.day);
          })
          .whereType<DateTime>()
          .toSet();

      final badgeDocMap = {
        for (final doc in badgeSnap.docs) doc.id: doc.data(),
      };
      final badges = kBadgeDefinitions
          .map((def) => Badge.fromDefinition(def, badgeDocMap[def['id']]))
          .toList();

      emit(StreakLoaded(
        streakData: _computeStreak(activeDays),
        badges: badges,
      ));
    } catch (_) {
      emit(const StreakError("Couldn't load streaks"));
    }
  }

  StreakData _computeStreak(Set<DateTime> activeDays) {
    if (activeDays.isEmpty) return StreakData.empty();

    final sorted = activeDays.toList()..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final yesterdayNorm = todayNorm.subtract(const Duration(days: 1));

    // Current streak — starts from today or yesterday
    int currentStreak = 0;
    DateTime? cursor = activeDays.contains(todayNorm)
        ? todayNorm
        : activeDays.contains(yesterdayNorm)
            ? yesterdayNorm
            : null;

    if (cursor != null) {
      for (final day in sorted) {
        if (day == cursor) {
          currentStreak++;
          cursor = cursor!.subtract(const Duration(days: 1));
        } else if (day.isBefore(cursor!)) {
          break;
        }
      }
    }

    // Longest streak
    int longest = sorted.isNotEmpty ? 1 : 0;
    int run = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i - 1].difference(sorted[i]).inDays == 1) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }

    return StreakData(
      currentStreak: currentStreak,
      longestStreak: longest,
      activeDays: activeDays,
    );
  }
}
