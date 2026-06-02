import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/break_suggestions.dart';
import '../cubits/active_timer_cubit.dart';
import '../cubits/session_cubit.dart';
import '../models/session_record.dart';
import '../models/wellness_model.dart';
import '../cubits/timer_cubit.dart';
import '../cubits/wellness_cubit.dart';
import '../models/break_suggestion.dart';
import '../models/timer_profile.dart';
import '../theme/app_colors.dart';
import '../widgets/add_timer_sheet.dart';
import '../widgets/animated_press.dart';
import '../widgets/playback_controls.dart';
import '../widgets/session_complete_sheet.dart';
import '../widgets/session_progress.dart';
import '../widgets/sound_selector_bar.dart';
import '../widgets/timer_card.dart';
import '../widgets/timer_display.dart';
import '../services/music_service.dart';
import '../widgets/sound_picker_sheet.dart';
import '../widgets/weekly_wellness_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ActiveTimerCubit()..loadProfiles()),
        BlocProvider(create: (_) => TimerCubit()),
        BlocProvider(create: (_) => SessionCubit()),
        BlocProvider(create: (_) => WellnessCubit()),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // When the active profile changes, reset the timer to the new profile
        BlocListener<ActiveTimerCubit, ActiveTimerState>(
          listenWhen: (prev, next) => prev.activeProfile != next.activeProfile,
          listener: (context, state) {
            if (state.activeProfile != null) {
              context.read<TimerCubit>().loadProfile(state.activeProfile!);
            }
          },
        ),
        // Sync music playback with timer state
        BlocListener<TimerCubit, TimerState>(
          listenWhen: (prev, next) => prev.runtimeType != next.runtimeType,
          listener: (context, state) {
            final music = MusicService.instance;
            if (state is TimerRunning || state is TimerOnBreak) {
              if (music.currentTrack != null && !music.isPlaying) {
                music.resume();
              }
            } else {
              if (music.isPlaying) music.pause();
            }
          },
        ),
        // When a session completes, show the mood check-in modal and save
        BlocListener<TimerCubit, TimerState>(
          listenWhen: (_, next) => next is TimerCompleted,
          listener: (context, state) {
            final timerCubit = context.read<TimerCubit>();
            final sessionCubit = context.read<SessionCubit>();
            final profile =
                context.read<ActiveTimerCubit>().state.activeProfile;
            final completed = (state as TimerCompleted).completedSessions;

            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => BlocProvider.value(
                value: sessionCubit..reset(),
                child: SessionCompleteSheet(
                  focusMins: (profile?.focusDuration ?? 0) ~/ 60,
                  sessionsCompleted: completed,
                  totalSessions: profile?.sessionsPerSit ?? 4,
                  buildRecord: (mood) {
                    final uid =
                        FirebaseAuth.instance.currentUser?.uid ?? '';
                    return SessionRecord(
                      id: '',
                      userId: uid,
                      timerProfileId: profile?.id ?? '',
                      focusDurationSeconds: profile?.focusDuration ?? 0,
                      completedSessions: completed,
                      mood: _toMoodRating(mood),
                      completedAt: DateTime.now(),
                    );
                  },
                ),
              ),
            ).then((_) => timerCubit.startBreak());
          },
        ),
      ],
      child: BlocBuilder<TimerCubit, TimerState>(
        builder: (context, timerState) {
          return BlocBuilder<ActiveTimerCubit, ActiveTimerState>(
            builder: (context, activeState) {
              final profile = activeState.activeProfile;

              // ── Break state ───────────────────────────────────────────────
              if (timerState is TimerOnBreak) {
                return Scaffold(
                  backgroundColor: Colors.white,
                  body: Column(
                    children: [
                      const _BreakHeader(),
                      Expanded(
                        child: _BreakBody(
                          state: timerState,
                          profile: profile,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // ── Focus / idle state ────────────────────────────────────────
              final isPlaying = timerState is TimerRunning;
              final canPlay = profile != null;

              return Scaffold(
                backgroundColor: Colors.white,
                bottomNavigationBar: _AddTimerBar(
                  onAdd: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    isDismissible: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => const AddTimerSheet(),
                  ),
                ),
                body: Column(
                  children: [
                    _Header(
                      greeting: _greeting,
                      userName:
                          FirebaseAuth.instance.currentUser?.displayName ??
                              'there',
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _TopActionIcons(
                              onAchievements: () =>
                                  context.push('/streaks'),
                              onMood: () {
                                final cubit = context.read<WellnessCubit>()
                                  ..loadWeeklySummary();
                                showDialog<void>(
                                  context: context,
                                  builder: (_) => BlocProvider.value(
                                    value: cubit,
                                    child: const WeeklyWellnessSheet(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: TimerDisplay(
                                timeLabel: _timeLabel(timerState, profile),
                                progress: _progress(timerState),
                                isPlaying: isPlaying,
                              ),
                            ),
                            const SizedBox(height: 18),
                            SessionProgress(
                              dots: _buildDots(timerState, profile),
                              label: _sessionLabel(timerState, profile),
                            ),
                            const SizedBox(height: 22),
                            PlaybackControls(
                              isPlaying: isPlaying,
                              onPlayPause: canPlay
                                  ? () => isPlaying
                                      ? context
                                          .read<TimerCubit>()
                                          .pauseTimer()
                                      : context
                                          .read<TimerCubit>()
                                          .startTimer()
                                  : null,
                              onRewind: timerState is! TimerInitial
                                  ? () =>
                                      context.read<TimerCubit>().resetTimer()
                                  : null,
                              onSkip: timerState is TimerRunning ||
                                      timerState is TimerPaused
                                  ? () =>
                                      context.read<TimerCubit>().startBreak()
                                  : null,
                            ),
                            const SizedBox(height: 22),
                            SoundSelectorBar(
                              onTap: () => showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20)),
                                ),
                                builder: (_) => const SoundPickerSheet(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _TimerList(
                              profiles: activeState.allProfiles,
                              activeId: profile?.id,
                              isLoading: activeState.isLoading,
                              errorMessage: activeState.errorMessage,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _timeLabel(TimerState state, TimerProfile? profile) {
    final seconds = switch (state) {
      TimerRunning s => s.remainingSeconds,
      TimerPaused s => s.remainingSeconds,
      TimerOnBreak s => s.remainingSeconds,
      _ => profile?.focusDuration ?? 0,
    };
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double _progress(TimerState state) {
    return switch (state) {
      TimerRunning s =>
        s.totalSeconds > 0 ? s.remainingSeconds / s.totalSeconds : 1.0,
      TimerPaused s =>
        s.totalSeconds > 0 ? s.remainingSeconds / s.totalSeconds : 1.0,
      TimerOnBreak s =>
        s.totalSeconds > 0 ? s.remainingSeconds / s.totalSeconds : 1.0,
      _ => 1.0,
    };
  }

  List<DotStatus> _buildDots(TimerState state, TimerProfile? profile) {
    final total = profile?.sessionsPerSit ?? 4;
    final completed = switch (state) {
      TimerRunning s => s.completedSessions,
      TimerCompleted s => s.completedSessions,
      _ => 0,
    };
    return List.generate(total, (i) {
      if (i < completed) return DotStatus.completed;
      if (i == completed) return DotStatus.current;
      return DotStatus.upcoming;
    });
  }

  MoodRating? _toMoodRating(Mood? mood) => switch (mood) {
        Mood.great => MoodRating.great,
        Mood.alright => MoodRating.alright,
        Mood.notWell => MoodRating.notSoWell,
        Mood.bad => MoodRating.bad,
        null => null,
      };

  String _sessionLabel(TimerState state, TimerProfile? profile) {
    final completed = switch (state) {
      TimerRunning s => s.completedSessions,
      TimerCompleted s => s.completedSessions,
      _ => 0,
    };
    final total = profile?.sessionsPerSit ?? 4;
    return '$completed/$total sessions complete';
  }
}

// ── Timer list ────────────────────────────────────────────────────────────────

class _TimerList extends StatelessWidget {
  final List<TimerProfile> profiles;
  final String? activeId;
  final bool isLoading;
  final String? errorMessage;

  const _TimerList({
    required this.profiles,
    required this.activeId,
    required this.isLoading,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            errorMessage!,
            style: const TextStyle(color: AppColors.subtitleText, fontSize: 13),
          ),
        ),
      );
    }
    if (profiles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No timers yet. Tap + to add one.',
            style: const TextStyle(
                color: AppColors.subtitleText, fontSize: 13),
          ),
        ),
      );
    }
    return Column(
      children: profiles
          .map((t) => TimerCard(
                timer: t,
                isActive: t.id == activeId,
                onTap: () =>
                    context.read<ActiveTimerCubit>().selectTimer(t.id),
              ))
          .toList(),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

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
            onTap: () => context.push('/account'),
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
            icon: const Icon(Icons.local_fire_department_rounded),
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

// ── Break state widgets ───────────────────────────────────────────────────────

class _BreakHeader extends StatelessWidget {
  const _BreakHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.teal,
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        bottom: 18,
      ),
      child: Center(
        child: Text(
          'Take A Break',
          style: GoogleFonts.openSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _BreakBody extends StatelessWidget {
  final TimerOnBreak state;
  final TimerProfile? profile;

  const _BreakBody({required this.state, this.profile});

  // Index is chosen once per break in TimerCubit.startBreak() — random, never repeats consecutively
  BreakSuggestion get _suggestion =>
      kBreakSuggestions[state.suggestionIndex % kBreakSuggestions.length];

  @override
  Widget build(BuildContext context) {
    final m = state.remainingSeconds ~/ 60;
    final s = state.remainingSeconds % 60;
    final timeLabel =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final progress = state.totalSeconds > 0
        ? state.remainingSeconds / state.totalSeconds
        : 1.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Center(
            child: TimerDisplay(
              timeLabel: timeLabel,
              progress: progress,
              isPlaying: true,
            ),
          ),
          const SizedBox(height: 24),
          // ── Content ──────────────────────────────────────────────────
          _SuggestionCard(suggestion: _suggestion),
          const SizedBox(height: 20),
          // ── Control ──────────────────────────────────────────────────
          SoundSelectorBar(
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => const SoundPickerSheet(),
            ),
          ),
          const SizedBox(height: 24),
          // ── Footer ───────────────────────────────────────────────────
          if (profile != null)
            Text(
              'Up next: ${profile!.name} · ${profile!.focusDuration ~/ 60} min',
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: AppColors.subtitleText,
              ),
            ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => context.read<TimerCubit>().skipBreak(),
            child: Text(
              'Skip Break',
              style: GoogleFonts.openSans(
                color: AppColors.subtitleText,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            'Your session progress is saved',
            style: GoogleFonts.openSans(
              color: AppColors.subtitleText.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final BreakSuggestion suggestion;

  const _SuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal.withValues(alpha: 0.12),
            ),
            child: Icon(
              _categoryIcon(suggestion.category),
              color: AppColors.teal,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  suggestion.description,
                  style: GoogleFonts.openSans(
                    fontSize: 11,
                    color: AppColors.subtitleText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) => switch (category) {
        'movement' => Icons.directions_walk_rounded,
        'breathing' => Icons.air_rounded,
        'hydration' => Icons.water_drop_rounded,
        'mindfulness' => Icons.self_improvement_rounded,
        _ => Icons.star_rounded,
      };
}

