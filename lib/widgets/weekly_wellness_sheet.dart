import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubits/wellness_cubit.dart';
import '../models/weekly_wellness_summary.dart';
import '../theme/app_colors.dart';

class WeeklyWellnessSheet extends StatelessWidget {
  const WeeklyWellnessSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.timerInnerFill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: BlocBuilder<WellnessCubit, WellnessState>(
          builder: (context, state) {
            if (state is WellnessLoading) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state is WellnessError) {
              return SizedBox(
                height: 120,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.message,
                          style: const TextStyle(
                              color: AppColors.subtitleText, fontSize: 13)),
                      TextButton(
                        onPressed: () =>
                            context.read<WellnessCubit>().loadWeeklySummary(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is WellnessLoaded) {
              return _WellnessContent(summary: state.summary);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _WellnessContent extends StatelessWidget {
  final WeeklyWellnessSummary summary;

  const _WellnessContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Weekly Wellness Summary',
          textAlign: TextAlign.center,
          style: GoogleFonts.openSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.darkNavy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _dateRange(summary.weekStart, summary.weekEnd),
          textAlign: TextAlign.center,
          style: GoogleFonts.openSans(
            fontSize: 12,
            color: AppColors.subtitleText,
          ),
        ),
        const SizedBox(height: 20),
        _StatsCard(summary: summary),
        const SizedBox(height: 20),
        _CloseButton(onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }

  static String _dateRange(DateTime start, DateTime end) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[start.month - 1]} ${start.day} – ${months[end.month - 1]} ${end.day}';
  }
}

class _StatsCard extends StatelessWidget {
  final WeeklyWellnessSummary summary;

  const _StatsCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final moodColor = _moodColor(summary.avgMoodScore);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
              value: summary.totalHours.toStringAsFixed(1),
              label: 'Hours'),
          const _StatDivider(),
          _StatItem(value: '${summary.totalSessions}', label: 'Sessions'),
          const _StatDivider(),
          _StatItem(
              value: '${(summary.completionRate * 100).toStringAsFixed(0)}%',
              label: 'Completion'),
          const _StatDivider(),
          _MoodStatItem(color: moodColor, label: 'Avg. Mood'),
        ],
      ),
    );
  }

  static Color _moodColor(double score) {
    if (score >= 3.5) return const Color(0xFF4CAF50);
    if (score >= 2.5) return const Color(0xFFFFCA28);
    if (score >= 1.5) return const Color(0xFFFF7043);
    return const Color(0xFFE91E63);
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.openSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
                fontSize: 10, color: Colors.white.withAlpha(200))),
      ],
    );
  }
}

class _MoodStatItem extends StatelessWidget {
  final Color color;
  final String label;

  const _MoodStatItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
                fontSize: 10, color: Colors.white.withAlpha(200))),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: Colors.white.withAlpha(60));
}

class _CloseButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _CloseButton({required this.onPressed});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: widget.onPressed,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.teal, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 11),
              backgroundColor: Colors.white,
            ),
            child: Text('Close',
                style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkNavy)),
          ),
        ),
      ),
    );
  }
}
