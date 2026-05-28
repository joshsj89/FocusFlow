import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/session_record.dart';

// ── States ────────────────────────────────────────────────────────────────────

abstract class SessionState extends Equatable {
  const SessionState();
  @override
  List<Object?> get props => [];
}

class SessionIdle extends SessionState {
  const SessionIdle();
}

class SessionSaving extends SessionState {
  const SessionSaving();
}

class SessionSaved extends SessionState {
  const SessionSaved();
}

class SessionSaveError extends SessionState {
  final String message;
  const SessionSaveError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class SessionCubit extends Cubit<SessionState> {
  SessionCubit() : super(const SessionIdle());

  Future<void> saveSession(SessionRecord record) async {
    emit(const SessionSaving());
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        emit(const SessionSaveError('Not authenticated'));
        return;
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .add(record.toMap());
      emit(const SessionSaved());
    } catch (_) {
      emit(const SessionSaveError("Couldn't save session. Try again."));
    }
  }

  void reset() => emit(const SessionIdle());
}
