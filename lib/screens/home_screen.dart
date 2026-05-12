import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/timer_display.dart';
import '../widgets/session_progress.dart';
import '../widgets/playback_controls.dart';
import '../widgets/sound_selector_bar.dart';
import '../widgets/timer_card.dart';
import '../widgets/add_timer_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isPlaying = false;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const AddTimerSheet(),
        ),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.teal,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        height: 60,
        padding: EdgeInsets.zero,
        child: const SizedBox.shrink(),
      ),
      body: Column(
        children: [
          _Header(greeting: _greeting, userName: 'Srinivasan'),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopActionIcons(
                    onAchievements: () {},
                    onMood: () {},
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: TimerDisplay(
                      timeLabel: '25:00',
                      progress: 0.82,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SessionProgress(
                    dots: [
                      DotStatus.completed,
                      DotStatus.completed,
                      DotStatus.current,
                      DotStatus.upcoming,
                      DotStatus.upcoming,
                      DotStatus.skipped,
                    ],
                    label: '7 sessions complete',
                  ),
                  const SizedBox(height: 22),
                  PlaybackControls(
                    isPlaying: _isPlaying,
                    onPlayPause: () => setState(() => _isPlaying = !_isPlaying),
                    onRewind: () {},
                    onPause: () => setState(() => _isPlaying = false),
                  ),
                  const SizedBox(height: 22),
                  const SoundSelectorBar(soundName: 'Ambient Rain'),
                  const SizedBox(height: 16),
                  const TimerCard(
                    title: 'Timer 1',
                    durationMins: 25,
                    sessions: 7,
                    isActive: true,
                  ),
                  const TimerCard(
                    title: 'Other Timers',
                    durationMins: 20,
                    sessions: 3,
                  ),
                  const TimerCard(
                    title: 'Other Timers',
                    durationMins: 20,
                    sessions: 3,
                  ),
                  const SizedBox(height: 90),
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
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/account');
            },
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
