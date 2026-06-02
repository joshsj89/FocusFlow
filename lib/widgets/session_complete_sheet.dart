import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/wellness_model.dart';
import '../theme/app_colors.dart';
import 'animated_press.dart';

class SessionCompleteSheet extends StatefulWidget {
  final int focusMins;
  final int sessionsCompleted;
  final int totalSessions;
  final void Function(Mood? mood) onDone;

  const SessionCompleteSheet({
    super.key,
    required this.focusMins,
    required this.sessionsCompleted,
    required this.totalSessions,
    required this.onDone,
  });

  @override
  State<SessionCompleteSheet> createState() => _SessionCompleteSheetState();
}

class _SessionCompleteSheetState extends State<SessionCompleteSheet> {
  Mood? _selectedMood;

  String get _focusTimeLabel {
    if (widget.focusMins < 60) return '${widget.focusMins} mins';
    final hrs = widget.focusMins ~/ 60;
    final rem = widget.focusMins % 60;
    return rem == 0 ? '${hrs}hrs' : '${hrs}hrs ${rem}m';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatLine(label: 'Focus Time:', value: _focusTimeLabel),
                const SizedBox(height: 4),
                _StatLine(
                  label: 'Session Completed:',
                  value: '${widget.sessionsCompleted}/${widget.totalSessions}',
                ),
                const SizedBox(height: 16),
                Text(
                  'How are you feeling?',
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 10),
                ...Mood.values.map(
                  (mood) => _MoodOption(
                    mood: mood,
                    selected: _selectedMood == mood,
                    onTap: () => setState(() => _selectedMood = mood),
                  ),
                ),
                const SizedBox(height: 18),
                _DoneButton(onPressed: () {
                  widget.onDone(_selectedMood);
                  Navigator.of(context).pop();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.timerInnerFill,
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          Text(
            'Session Complete',
            style: GoogleFonts.openSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Great Work!',
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: AppColors.subtitleText,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;

  const _StatLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.openSans(fontSize: 13, color: AppColors.darkNavy);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: label, style: base.copyWith(fontWeight: FontWeight.w700)),
          TextSpan(text: ' $value', style: base),
        ],
      ),
    );
  }
}

class _MoodOption extends StatelessWidget {
  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  const _MoodOption({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: onTap,
      pressedScale: 0.95,
      hoveredScale: 1.02,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mood.color,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              mood.label,
              style: GoogleFonts.openSans(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.darkNavy : AppColors.subtitleText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoneButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _DoneButton({required this.onPressed});

  @override
  State<_DoneButton> createState() => _DoneButtonState();
}

class _DoneButtonState extends State<_DoneButton> {
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
                backgroundColor: AppColors.timerInnerFill,
              ),
              child: Text(
                'Done',
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
