import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/timer_model.dart';
import '../services/timer_service.dart';
import '../services/streak_service.dart';
import '../services/wellness_service.dart';
import '../models/wellness_model.dart';
import '../theme/app_colors.dart';
import '../widgets/timer_display.dart';
import '../widgets/session_progress.dart';
import '../widgets/playback_controls.dart';
import '../widgets/sound_selector_bar.dart';
import '../widgets/timer_card.dart';
import '../widgets/add_timer_sheet.dart';
import '../widgets/edit_timer_sheet.dart';
import '../widgets/streaks_sheet.dart';
import '../widgets/session_complete_sheet.dart';
import '../widgets/weekly_wellness_sheet.dart';
import '../widgets/animated_press.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TimerModel? _activeTimer;
  bool _isPlaying = false;
  late int _secondsRemaining;
  int _currentSession = 1;
  Timer? _countdownTimer;
  StreamSubscription<UserAccelerometerEvent>? _motionSub;
  late final Stream<List<TimerModel>> _timerStream;

  int get _totalSeconds => (_activeTimer?.durationMins ?? 25) * 60;
  int get _totalSessions => _activeTimer?.sessions ?? 1;

  List<DotStatus> get _sessionDots => List.generate(_totalSessions, (i) {
        if (i + 1 < _currentSession) return DotStatus.completed;
        if (i + 1 == _currentSession) return DotStatus.current;
        return DotStatus.upcoming;
      });

  String get _sessionLabel {
    final completed = _currentSession - 1;
    if (completed == 0) return 'Session 1 of $_totalSessions';
    return '$completed of $_totalSessions sessions complete';
  }

  @override
  void initState() {
    super.initState();
    _secondsRemaining = _totalSeconds;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _timerStream = TimerService.watchTimers(uid);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _startMotionDetection();
    }
  }

  @override
  void dispose() {
    _motionSub?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

// this'll pause the timer when the phone gets picked up
  void _startMotionDetection() {
    _motionSub = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen((event) {
      if (!_isPlaying || !mounted) return;
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      if (magnitude > 3.0) {
        _togglePlayPause();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timer paused, put the phone down!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }, onError: (_) {
      // sensor unavailable on this device — no-op
    });
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _timeLabel {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => _secondsRemaining / _totalSeconds;

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining <= 1) {
        _countdownTimer?.cancel();
        setState(() {
          _secondsRemaining = 0;
          _isPlaying = false;
        });
        _onSessionComplete();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _onSessionComplete() {
    if (_currentSession < _totalSessions) {
      setState(() {
        _currentSession++;
        _secondsRemaining = _totalSeconds;
      });
    } else {
      final completed = _currentSession;
      final total = _totalSessions;
      setState(() {
        _currentSession = 1;
        _secondsRemaining = _totalSeconds;
      });
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) StreakService.recordToday(uid);
      _showSessionComplete(completed, total);
    }
  }

  void _selectTimer(TimerModel timer) {
    _countdownTimer?.cancel();
    setState(() {
      _activeTimer = timer;
      _isPlaying = false;
      _currentSession = 1;
      _secondsRemaining = timer.durationMins * 60;
    });
  }

  void _togglePlayPause() {
    final willPlay = !_isPlaying;
    setState(() => _isPlaying = willPlay);
    if (willPlay) {
      _startCountdown();
    } else {
      _countdownTimer?.cancel();
    }
  }

  void _rewind() {
    _countdownTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _currentSession = 1;
      _secondsRemaining = _totalSeconds;
    });
  }

  void _showSessionComplete(int sessionsCompleted, int totalSessions) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final focusMins = (_activeTimer?.durationMins ?? 25) * sessionsCompleted;
    showDialog<Mood>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SessionCompleteSheet(
        focusMins: focusMins,
        sessionsCompleted: sessionsCompleted,
        totalSessions: totalSessions,
      ),
    ).then((mood) {
      if (uid != null) {
        WellnessService.recordEntry(
          uid,
          mood: mood,
          focusMins: focusMins,
          sessionsCompleted: sessionsCompleted,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _AddTimerBar(
        onAdd: () => showDialog<void>(
          context: context,
          builder: (_) => const AddTimerSheet(),
        ),
      ),
      body: Column(
        children: [
          _Header(
            greeting: _greeting,
            userName: FirebaseAuth.instance.currentUser?.displayName ?? 'there',
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopActionIcons(
                    onAchievements: () => showDialog<void>(
                      context: context,
                      builder: (_) => const StreaksSheet(),
                    ),
                    onMood: () => showDialog<void>(
                      context: context,
                      builder: (_) => const WeeklyWellnessSheet(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TimerDisplay(
                      timeLabel: _timeLabel,
                      progress: _progress,
                      isPlaying: _isPlaying,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SessionProgress(
                    dots: _sessionDots,
                    label: _sessionLabel,
                  ),
                  const SizedBox(height: 22),
                  PlaybackControls(
                    isPlaying: _isPlaying,
                    onPlayPause: _togglePlayPause,
                    onRewind: _rewind,
                    onCancel: _rewind,
                  ),
                  const SizedBox(height: 22),
                  const SoundSelectorBar(soundName: 'Ambient Rain'),
                  const SizedBox(height: 16),
                  StreamBuilder<List<TimerModel>>(
                    stream: _timerStream,
                    builder: (context, snapshot) {
                      final timers = snapshot.data ?? [];
                      if (_activeTimer == null && timers.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _activeTimer == null) {
                            _selectTimer(timers.first);
                          }
                        });
                      }
                      if (timers.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No timers yet. Tap + to add one.',
                              style: TextStyle(
                                color: AppColors.subtitleText,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: timers
                            .map((t) => TimerCard(
                                  timer: t,
                                  isActive: _activeTimer?.id == t.id,
                                  onTap: () => _selectTimer(t),
                                  onEdit: () => showDialog<void>(
                                    context: context,
                                    builder: (_) => EditTimerSheet(timer: t),
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String greeting;
  final String userName;

  const _Header({required this.greeting, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.teal,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        left: 20,
        right: 20,
        bottom: 18,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$greeting, $userName',
              style: GoogleFonts.openSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          AnimatedPress(
            onTap: () => Navigator.pushNamed(context, '/account'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(70),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTimerBar extends StatelessWidget {
  final VoidCallback onAdd;

  const _AddTimerBar({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: AnimatedPress(
        onTap: onAdd,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withAlpha(80),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                'Add Timer',
                style: GoogleFonts.openSans(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopActionIcons extends StatelessWidget {
  final VoidCallback onAchievements;
  final VoidCallback onMood;

  const _TopActionIcons({
    required this.onAchievements,
    required this.onMood,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.star_border_rounded),
            color: AppColors.purple,
            onPressed: onAchievements,
          ),
          IconButton(
            icon: const Icon(Icons.sentiment_satisfied_alt_outlined),
            color: AppColors.purple,
            onPressed: onMood,
          ),
        ],
      ),
    );
  }
}
