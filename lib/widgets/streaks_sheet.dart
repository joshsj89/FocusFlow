import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/streak_model.dart';
import '../services/streak_service.dart';
import '../theme/app_colors.dart';
import 'animated_press.dart';

class StreaksSheet extends StatelessWidget {
  const StreaksSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final monthLabel = _monthName(now.month);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: StreamBuilder<StreakModel>(
          stream: uid != null
              ? StreakService.watchStreaks(uid)
              : const Stream.empty(),
          initialData: StreakModel.empty(),
          builder: (context, snapshot) {
            final model = snapshot.data ?? StreakModel.empty();
            final streakDays = model.activeDaysInMonth(now.year, now.month);
            final streakCount = model.currentStreak;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TitleRow(onClose: () => Navigator.of(context).pop()),
                const SizedBox(height: 16),
                _StreakInfoCard(count: streakCount),
                const SizedBox(height: 16),
                Text(
                  monthLabel,
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 8),
                _CalendarGrid(
                  daysInMonth: daysInMonth,
                  streakDays: streakDays,
                ),
                const SizedBox(height: 20),
                _CloseButton(onPressed: () => Navigator.of(context).pop()),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }
}

class _TitleRow extends StatelessWidget {
  final VoidCallback onClose;

  const _TitleRow({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Streaks',
          style: GoogleFonts.openSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.darkNavy,
          ),
        ),
        const Spacer(),
        AnimatedPress(
          onTap: onClose,
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.purple,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}

class _StreakInfoCard extends StatelessWidget {
  final int count;

  const _StreakInfoCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.teal, width: 1.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.sentiment_satisfied_alt_outlined,
            size: 32,
            color: AppColors.darkNavy,
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: GoogleFonts.openSans(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Keep it Up!',
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: AppColors.subtitleText,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final int daysInMonth;
  final Set<int> streakDays;

  const _CalendarGrid({required this.daysInMonth, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      children: List.generate(daysInMonth, (i) {
        final day = i + 1;
        return _DayCell(day: day, isStreak: streakDays.contains(day));
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isStreak;

  const _DayCell({required this.day, required this.isStreak});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isStreak ? AppColors.teal : Colors.transparent,
        border: Border.all(
          color: isStreak ? AppColors.teal : AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          '$day',
          style: GoogleFonts.openSans(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isStreak ? Colors.white : AppColors.darkNavy,
          ),
        ),
      ),
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: AppColors.timerInnerFill,
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
