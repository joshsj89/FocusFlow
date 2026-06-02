import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubits/streak_cubit.dart';
import '../models/badge.dart';
import '../models/streak_data.dart';
import '../theme/app_colors.dart';

class StreaksScreen extends StatelessWidget {
  const StreaksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StreakCubit()..loadStreaks(),
      child: const _StreaksView(),
    );
  }
}

class _StreaksView extends StatelessWidget {
  const _StreaksView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.darkNavy),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Streaks',
          style: GoogleFonts.openSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.darkNavy,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<StreakCubit, StreakState>(
        builder: (context, state) {
          if (state is StreakLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is StreakError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.subtitleText),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: const TextStyle(color: AppColors.subtitleText)),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        context.read<StreakCubit>().loadStreaks(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is StreakLoaded) {
            return _StreakContent(
              streakData: state.streakData,
              badges: state.badges,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _StreakContent extends StatelessWidget {
  final StreakData streakData;
  final List<Badge> badges;

  const _StreakContent({required this.streakData, required this.badges});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StreakInfoCard(
            current: streakData.currentStreak,
            longest: streakData.longestStreak,
          ),
          const SizedBox(height: 20),
          Text(
            _monthName(now.month),
            style: GoogleFonts.openSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 8),
          _CalendarGrid(
            year: now.year,
            month: now.month,
            activeDays: streakData.activeDays,
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Badges',
              style: GoogleFonts.openSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            ...badges.map((b) => _BadgeRow(badge: b)),
          ],
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => _confirmClear(context),
              child: Text(
                'Clear streak',
                style: GoogleFonts.openSans(
                  color: AppColors.subtitleText,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset your streak?',
            style: GoogleFonts.openSans(fontWeight: FontWeight.w600)),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // streak is computed from sessions — clearing sessions is out of scope;
              // for now this simply reloads to reflect current state
              context.read<StreakCubit>().loadStreaks();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  static String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StreakInfoCard extends StatelessWidget {
  final int current;
  final int longest;

  const _StreakInfoCard({required this.current, required this.longest});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.teal, width: 1.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatCol(value: '$current', label: 'Current streak'),
          Container(width: 1, height: 40, color: AppColors.cardBorder),
          _StatCol(value: '$longest', label: 'Longest streak'),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String value;
  final String label;

  const _StatCol({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.openSans(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.darkNavy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 11,
            color: AppColors.subtitleText,
          ),
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final Set<DateTime> activeDays;

  const _CalendarGrid({
    required this.year,
    required this.month,
    required this.activeDays,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    // Monday-first offset (0=Mon … 6=Sun → shift so week starts Monday)
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon, 7=Sun
    final offset = firstWeekday - 1; // cells to leave blank before day 1

    final activeInMonth = activeDays
        .where((d) => d.year == year && d.month == month)
        .map((d) => d.day)
        .toSet();

    final today = DateTime.now();
    final todayDay =
        (today.year == year && today.month == month) ? today.day : -1;

    final totalCells = offset + daysInMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day-of-week header
        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: GoogleFonts.openSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subtitleText,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
          ),
          itemCount: totalCells,
          itemBuilder: (_, index) {
            if (index < offset) return const SizedBox.shrink();
            final day = index - offset + 1;
            return _DayCell(
              day: day,
              isActive: activeInMonth.contains(day),
              isToday: day == todayDay,
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isActive;
  final bool isToday;

  const _DayCell(
      {required this.day, required this.isActive, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.teal : Colors.transparent,
        border: Border.all(
          color: isToday
              ? AppColors.purple
              : isActive
                  ? AppColors.teal
                  : AppColors.cardBorder,
          width: isToday ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          '$day',
          style: GoogleFonts.openSans(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : AppColors.darkNavy,
          ),
        ),
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final Badge badge;

  const _BadgeRow({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badge.earned
                  ? AppColors.teal.withValues(alpha: 0.15)
                  : AppColors.cardBorder.withValues(alpha: 0.5),
            ),
            child: Icon(
              Icons.military_tech_rounded,
              size: 22,
              color:
                  badge.earned ? AppColors.teal : AppColors.subtitleText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.title,
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: badge.earned
                        ? AppColors.darkNavy
                        : AppColors.subtitleText,
                  ),
                ),
                Text(
                  badge.description,
                  style: GoogleFonts.openSans(
                    fontSize: 11,
                    color: AppColors.subtitleText,
                  ),
                ),
              ],
            ),
          ),
          if (badge.earned)
            const Icon(Icons.check_circle_rounded,
                color: AppColors.teal, size: 18),
        ],
      ),
    );
  }
}
