import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/wellness_model.dart';
import '../services/wellness_service.dart';
import '../theme/app_colors.dart';

class WeeklyWellnessSheet extends StatelessWidget {
  const WeeklyWellnessSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Dialog(
      backgroundColor: AppColors.timerInnerFill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: StreamBuilder<WeeklyWellnessStats>(
          stream: uid != null
              ? WellnessService.watchWeeklyStats(uid)
              : const Stream.empty(),
          initialData: WeeklyWellnessStats.empty(),
          builder: (context, snapshot) {
            final stats = snapshot.data ?? WeeklyWellnessStats.empty();
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
                const SizedBox(height: 20),
                _StatsCard(stats: stats),
                const SizedBox(height: 20),
                _CloseButton(onPressed: () => Navigator.of(context).pop()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final WeeklyWellnessStats stats;

  const _StatsCard({required this.stats});

  String get _hoursLabel {
    final h = stats.hoursFocused;
    if (h < 1) return '${(h * 60).round()}m';
    return h == h.truncateToDouble() ? '${h.toInt()}h' : h.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(value: _hoursLabel, label: 'Hours Focused'),
          const _StatDivider(),
          _StatItem(value: '${stats.sessionsCompleted}', label: 'Sessions'),
          const _StatDivider(),
          _StatItem(value: '${stats.completionPct}%', label: 'Completion Rate'),
          const _StatDivider(),
          _MoodStatItem(label: 'Avg. Mood', color: stats.avgMoodColor),
        ],
      ),
    );
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
        Text(
          value,
          style: GoogleFonts.openSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.openSans(
            fontSize: 10,
            color: Colors.white.withAlpha(200),
          ),
        ),
      ],
    );
  }
}

class _MoodStatItem extends StatelessWidget {
  final String label;
  final Color? color;

  const _MoodStatItem({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? Colors.white.withAlpha(60),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.openSans(
            fontSize: 10,
            color: Colors.white.withAlpha(200),
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withAlpha(60),
    );
  }
}

class _CloseButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _CloseButton({required this.onPressed});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : (_hovered ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.teal, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                backgroundColor: Colors.white,
              ),
              child: Text(
                'Close',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkNavy,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
