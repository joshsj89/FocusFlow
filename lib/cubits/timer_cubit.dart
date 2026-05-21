import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/timer_profile.dart';

enum TimerPhase { focus, shortBreak, longBreak }

// ── States ────────────────────────────────────────────────────────────────────

abstract class TimerState extends Equatable {
  const TimerState();
  @override
  List<Object?> get props => [];
}

class TimerInitial extends TimerState {
  const TimerInitial();
}

class TimerRunning extends TimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final int completedSessions;
  final TimerPhase phase;

  const TimerRunning({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.completedSessions,
    required this.phase,
  });

  @override
  List<Object?> get props =>
      [remainingSeconds, totalSeconds, completedSessions, phase];
}

class TimerPaused extends TimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final TimerPhase phase;

  const TimerPaused({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.phase,
  });

  @override
  List<Object?> get props => [remainingSeconds, totalSeconds, phase];
}

class TimerCompleted extends TimerState {
  final int completedSessions;

  const TimerCompleted({required this.completedSessions});

  @override
  List<Object?> get props => [completedSessions];
}

class TimerOnBreak extends TimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final String nextTimerName;

  const TimerOnBreak({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.nextTimerName,
  });

  @override
  List<Object?> get props => [remainingSeconds, totalSeconds, nextTimerName];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class TimerCubit extends Cubit<TimerState> {
  TimerCubit() : super(const TimerInitial());

  TimerProfile? _profile;
  Timer? _ticker;
  int _remainingSeconds = 0;
  int _completedSessions = 0;
  TimerPhase _phase = TimerPhase.focus;

  void loadProfile(TimerProfile profile) {
    _cancelTicker();
    _profile = profile;
    _remainingSeconds = profile.focusDuration;
    _completedSessions = 0;
    _phase = TimerPhase.focus;
    emit(const TimerInitial());
  }

  void startTimer() {
    if (_profile == null) return;
    _cancelTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    emit(TimerRunning(
      remainingSeconds: _remainingSeconds,
      totalSeconds: _currentTotal,
      completedSessions: _completedSessions,
      phase: _phase,
    ));
  }

  void pauseTimer() {
    _cancelTicker();
    emit(TimerPaused(
      remainingSeconds: _remainingSeconds,
      totalSeconds: _currentTotal,
      phase: _phase,
    ));
  }

  void resetTimer() {
    _cancelTicker();
    _remainingSeconds = _profile?.focusDuration ?? 0;
    _phase = TimerPhase.focus;
    emit(TimerPaused(
      remainingSeconds: _remainingSeconds,
      totalSeconds: _remainingSeconds,
      phase: _phase,
    ));
  }

  // Called by the UI after the session complete modal is dismissed
  void startBreak() {
    if (_profile == null) return;
    _cancelTicker();
    _phase = _completedSessions % _profile!.sessionsPerSit == 0
        ? TimerPhase.longBreak
        : TimerPhase.shortBreak;
    _remainingSeconds = _profile!.breakDuration;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    emit(TimerOnBreak(
      remainingSeconds: _remainingSeconds,
      totalSeconds: _profile!.breakDuration,
      nextTimerName: _profile!.name,
    ));
  }

  void skipBreak() {
    if (state is! TimerOnBreak) return;
    _cancelTicker();
    _phase = TimerPhase.focus;
    _remainingSeconds = _profile!.focusDuration;
    emit(const TimerInitial());
  }

  void _tick() {
    if (_remainingSeconds <= 1) {
      _cancelTicker();
      _remainingSeconds = 0;

      if (_phase == TimerPhase.focus) {
        _completedSessions++;
        emit(TimerCompleted(completedSessions: _completedSessions));
      } else {
        // Break ended — return to idle so user can start the next session
        _phase = TimerPhase.focus;
        _remainingSeconds = _profile!.focusDuration;
        emit(const TimerInitial());
      }
    } else {
      _remainingSeconds--;
      if (_phase == TimerPhase.focus) {
        emit(TimerRunning(
          remainingSeconds: _remainingSeconds,
          totalSeconds: _currentTotal,
          completedSessions: _completedSessions,
          phase: _phase,
        ));
      } else {
        emit(TimerOnBreak(
          remainingSeconds: _remainingSeconds,
          totalSeconds: _currentTotal,
          nextTimerName: _profile!.name,
        ));
      }
    }
  }

  int get _currentTotal {
    if (_profile == null) return 0;
    return _phase == TimerPhase.focus
        ? _profile!.focusDuration
        : _profile!.breakDuration;
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  Future<void> close() {
    _cancelTicker();
    return super.close();
  }
}
