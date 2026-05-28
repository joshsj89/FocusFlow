import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/session_record.dart';
import '../models/weekly_wellness_summary.dart';

// ── States ────────────────────────────────────────────────────────────────────

abstract class WellnessState extends Equatable {
  const WellnessState();
  @override
  List<Object?> get props => [];
}

class WellnessLoading extends WellnessState {
  const WellnessLoading();
}

class WellnessLoaded extends WellnessState {
  final WeeklyWellnessSummary summary;
  const WellnessLoaded(this.summary);
  @override
  List<Object?> get props => [summary];
}

class WellnessError extends WellnessState {
  final String message;
  const WellnessError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class WellnessCubit extends Cubit<WellnessState> {
  WellnessCubit() : super(const WellnessLoading());

  Future<void> loadWeeklySummary() async {
    emit(const WellnessLoading());
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        emit(const WellnessError('Not authenticated'));
        return;
      }

      final now = DateTime.now();
      // Week starts on Monday
      final weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('completedAt', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
          .get();

      final sessions = snap.docs
          .map((doc) => SessionRecord.fromMap(doc.data(), id: doc.id))
          .toList();

      emit(WellnessLoaded(
        WeeklyWellnessSummary.fromSessions(sessions, weekStart, weekEnd),
      ));
    } catch (_) {
      emit(const WellnessError("Couldn't load your summary"));
    }
  }
}
