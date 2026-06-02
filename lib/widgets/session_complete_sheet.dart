import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubits/session_cubit.dart';
import '../models/session_record.dart';
import '../models/wellness_model.dart';
import '../theme/app_colors.dart';
import 'animated_press.dart';

class SessionCompleteSheet extends StatefulWidget {
  final int focusMins;
  final int sessionsCompleted;
  final int totalSessions;
  // Record is built lazily (mood isn't known until Done is tapped)
  final SessionRecord Function(Mood? mood) buildRecord;

  const SessionCompleteSheet({
    super.key,
    required this.focusMins,
    required this.sessionsCompleted,
    required this.totalSessions,
    required this.buildRecord,
  });

  @override
  State<SessionCompleteSheet> createState() => _SessionCompleteSheetState();
}

class _SessionCompleteSheetState extends State<SessionCompleteSheet> {
  Mood? _selectedMood;
  String? _errorMessage;

  String get _focusTimeLabel {
    if (widget.focusMins < 60) return '${widget.focusMins} mins';
    final hrs = widget.focusMins ~/ 60;
    final rem = widget.focusMins % 60;
    return rem == 0 ? '${hrs}hrs' : '${hrs}hrs ${rem}m';
  }

  void _onDone(BuildContext context) {
    if (_selectedMood == null) {
      // No mood selected — dismiss without saving
      Navigator.of(context).pop();
      return;
    }
    // Save session; BlocListener handles close on success, error on failure
    context
        .read<SessionCubit>()
        .saveSession(widget.buildRecord(_selectedMood));
  }

  @override
  Widget build(BuildContext context) {
    // PopScope(canPop: false) blocks the Android hardware back button
    return PopScope(
      canPop: false,
      child: BlocConsumer<SessionCubit, SessionState>(
        listenWhen: (prev, next) => prev != next,
        listener: (context, state) {
          if (state is SessionSaved) {
            Navigator.of(context).pop();
          }
          if (state is SessionSaveError) {
            setState(() => _errorMessage = state.message);
          }
        },
        builder: (context, sessionState) {
          final isSaving = sessionState is SessionSaving;

          return Dialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 40),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Header(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatLine(
                          label: 'Focus Time:', value: _focusTimeLabel),
                      const SizedBox(height: 4),
                      _StatLine(
                        label: 'Session Completed:',
                        value:
                            '${widget.sessionsCompleted}/${widget.totalSessions}',
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
                          onTap: isSaving
                              ? null
                              : () => setState(() {
                                    _selectedMood = mood;
                                    _errorMessage = null;
                                  }),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.error_outline,
                                size: 14, color: Colors.red.shade400),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$_errorMessage Tap Done to retry.',
                                style: GoogleFonts.openSans(
                                  fontSize: 11,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      _DoneButton(
                        isSaving: isSaving,
                        onPressed: isSaving ? null : () => _onDone(context),
                      ),
                      if (_selectedMood == null)
                        Center(
                          child: TextButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: Text(
                              'Skip for now',
                              style: GoogleFonts.openSans(
                                fontSize: 12,
                                color: AppColors.subtitleText,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
    final base =
        GoogleFonts.openSans(fontSize: 13, color: AppColors.darkNavy);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
              text: label,
              style: base.copyWith(fontWeight: FontWeight.w700)),
          TextSpan(text: ' $value', style: base),
        ],
      ),
    );
  }
}

class _MoodOption extends StatelessWidget {
  final Mood mood;
  final bool selected;
  final VoidCallback? onTap;

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
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? AppColors.darkNavy
                    : AppColors.subtitleText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback? onPressed;

  const _DoneButton({required this.isSaving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.teal, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 11),
          backgroundColor: AppColors.timerInnerFill,
        ),
        child: isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation(AppColors.teal),
                ),
              )
            : Text(
                'Done',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkNavy,
                ),
              ),
      ),
    );
  }
}
