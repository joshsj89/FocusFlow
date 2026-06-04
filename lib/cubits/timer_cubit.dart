import 'dart:async';
import 'dart:math' show Random, sqrt;
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import '../constants/break_suggestions.dart';
import '../models/timer_profile.dart';

enum TimerPhase { focus, shortBreak, longBreak }

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
  final int suggestionIndex; // index into kBreakSuggestions, picked once per break

  const TimerOnBreak({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.nextTimerName,
    required this.suggestionIndex,
  });

  @override
  List<Object?> get props =>
      [remainingSeconds, totalSeconds, nextTimerName, suggestionIndex];
}


class TimerCubit extends Cubit<TimerState> with WidgetsBindingObserver {
  TimerCubit() : super(const TimerInitial()) {
    WidgetsBinding.instance.addObserver(this);
  }

  TimerProfile? _profile;
  Timer? _ticker;
  int _remainingSeconds = 0;
  int _completedSessions = 0;
  TimerPhase _phase = TimerPhase.focus;
  int _lastSuggestionIndex = -1;
  DateTime? _backgroundedAt; // stamped when app is paused, used to fast-forward on resume
  StreamSubscription<AccelerometerEvent>? _motionSub;
  StreamSubscription<dynamic>? _proximitySub;
  bool _phoneIsDown = false;

  // Resting gravity vector (EMA) used to detect pick-up
  double _gx = 0, _gy = 0, _gz = 0;
  bool _gravityInitialized = false;
  int _pickupFrames = 0;
  static const _kGravityAlpha = 0.05; // tracks resting orientation
  static const _kPickupThreshold = 4.0;
  static const _kPickupFrames = 4; // ~400 ms

  void loadProfile(TimerProfile profile) {
    _cancelTicker();
    _profile = profile;
    _remainingSeconds = profile.focusDuration.clamp(60, 8 * 3600);
    _completedSessions = 0;
    _phase = TimerPhase.focus;
    emit(const TimerInitial());
    _startSensors();
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

  void incrementSession() { // Called by the UI when skip button is pressed
    if (_profile == null) return;
    _cancelTicker();
    _completedSessions++;
    emit(TimerCompleted(completedSessions: _completedSessions));
  }

  // Called by the UI after the session complete modal is dismissed
  void startBreak() {
    if (_profile == null) return;
    _cancelTicker();
    _phase = _completedSessions % _profile!.sessionsPerSit == 0
        ? TimerPhase.longBreak
        : TimerPhase.shortBreak;
    _remainingSeconds = _profile!.breakDuration.clamp(60, 2 * 3600);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());

    // Pick a random suggestion, avoiding the same one as last break
    final total = kBreakSuggestions.length;
    int index;
    do {
      index = Random().nextInt(total);
    } while (index == _lastSuggestionIndex && total > 1);
    _lastSuggestionIndex = index;

    emit(TimerOnBreak(
      remainingSeconds: _remainingSeconds,
      totalSeconds: _profile!.breakDuration,
      nextTimerName: _profile!.name,
      suggestionIndex: index,
    ));
  }

  void skipBreak() {
    if (state is! TimerOnBreak) return;
    _cancelTicker();
    _startNextFocus();
    // Auto-start the next focus session rather than returning to idle
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    emit(TimerRunning(
      remainingSeconds: _remainingSeconds,
      totalSeconds: _profile!.focusDuration,
      completedSessions: _completedSessions,
      phase: _phase,
    ));
  }

  // ── App lifecycle ─────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (this.state is TimerRunning || this.state is TimerOnBreak) {
        _backgroundedAt = DateTime.now();
        _cancelTicker();
      }
    } else if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  void _onAppResumed() {
    final backgroundedAt = _backgroundedAt;
    if (backgroundedAt == null) return;
    _backgroundedAt = null;

    if (state is! TimerRunning && state is! TimerOnBreak) return;

    final elapsed = DateTime.now().difference(backgroundedAt).inSeconds;
    _remainingSeconds = (_remainingSeconds - elapsed).clamp(0, _remainingSeconds);

    if (_remainingSeconds <= 0) {
      _completeCurrentPhase();
    } else {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      _emitActiveState();
    }
  }

  void _emitActiveState() {
    if (state is TimerOnBreak || _phase != TimerPhase.focus) {
      emit(TimerOnBreak(
        remainingSeconds: _remainingSeconds,
        totalSeconds: _currentTotal,
        nextTimerName: _profile!.name,
        suggestionIndex: _lastSuggestionIndex,
      ));
    } else {
      emit(TimerRunning(
        remainingSeconds: _remainingSeconds,
        totalSeconds: _currentTotal,
        completedSessions: _completedSessions,
        phase: _phase,
      ));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  void _startNextFocus() {
    if (_completedSessions >= _profile!.sessionsPerSit) {
      _completedSessions = 0;
    }
    _phase = TimerPhase.focus;
    _remainingSeconds = _profile!.focusDuration;
  }

  // ── Tick ──────────────────────────────────────────────────────────────────────


  void _tick() {
    if (_remainingSeconds <= 1) {
      _cancelTicker();
      _remainingSeconds = 0;
      _completeCurrentPhase();
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
          suggestionIndex: _lastSuggestionIndex,
        ));
      }
    }
  }

  void _completeCurrentPhase() {
    if (_phase == TimerPhase.focus) {
      _completedSessions++;
      _vibrateComplete();
      emit(TimerCompleted(completedSessions: _completedSessions));
    } else {
      // Break ended — reset sessions if a full sit is done, then return to idle
      _startNextFocus();
      emit(const TimerInitial());
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

  void _startSensors() {
    _stopSensors();
    if (kIsWeb) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      _gravityInitialized = false;
      _pickupFrames = 0;
      _motionSub = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 100),
      ).listen((event) {
        if (!_gravityInitialized) {
          _gx = event.x; _gy = event.y; _gz = event.z;
          _gravityInitialized = true;
          return;
        }

        if (state is! TimerRunning) {
          // Keep resting vector up to date while paused/idle
          _gx = _kGravityAlpha * event.x + (1 - _kGravityAlpha) * _gx;
          _gy = _kGravityAlpha * event.y + (1 - _kGravityAlpha) * _gy;
          _gz = _kGravityAlpha * event.z + (1 - _kGravityAlpha) * _gz;
          _pickupFrames = 0;
          return;
        }

        final dx = event.x - _gx;
        final dy = event.y - _gy;
        final dz = event.z - _gz;
        final delta = sqrt(dx * dx + dy * dy + dz * dz);

        if (delta > _kPickupThreshold) {
          _pickupFrames++;
          if (_pickupFrames >= _kPickupFrames) {
            _pickupFrames = 0;
            pauseTimer();
          }
        } else {
          _pickupFrames = 0;
          // Slowly update resting vector while phone is still during a session
          _gx = _kGravityAlpha * event.x + (1 - _kGravityAlpha) * _gx;
          _gy = _kGravityAlpha * event.y + (1 - _kGravityAlpha) * _gy;
          _gz = _kGravityAlpha * event.z + (1 - _kGravityAlpha) * _gz;
        }
      }, onError: (_) {});
    }

    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      _proximitySub = ProximitySensor.events.listen((int event) {
        final isNear = event > 0; // ProximitySensor event is 0 for far, 1 for near
        if (isNear == _phoneIsDown) return; // no changes
        _phoneIsDown = isNear;
        final s = state;
        if (isNear && (s is TimerInitial || s is TimerPaused)) {
          startTimer();
        } else if (!isNear && s is TimerRunning) {
          pauseTimer();
        }
      }, onError: (_) {});
    }
  }

  void _stopSensors() {
    _motionSub?.cancel();
    _motionSub = null;
    _proximitySub?.cancel();
    _proximitySub = null;
  }

  Future<void> _vibrateComplete() async {
    if (kIsWeb) return;
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 150, 80, 150, 80, 500]);
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTicker();
    _stopSensors();
    return super.close();
  }
}
