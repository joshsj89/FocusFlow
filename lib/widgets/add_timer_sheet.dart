import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubits/timer_form_cubit.dart';
import '../theme/app_colors.dart';
import 'timer_sheet_widgets.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

class AddTimerSheet extends StatelessWidget {
  const AddTimerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TimerFormCubit(),
      child: const TimerFormBody(title: 'New Timer', isEdit: false),
    );
  }
}

// ── Shared form body (also used by EditTimerSheet) ────────────────────────────

class TimerFormBody extends StatelessWidget {
  final String title;
  final bool isEdit;

  const TimerFormBody({super.key, required this.title, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    return BlocListener<TimerFormCubit, TimerFormState>(
      listenWhen: (prev, next) => prev.status != next.status,
      listener: (context, state) {
        if (state.status == FormStatus.saved) {
          Navigator.of(context).pop();
        }
        if (state.status == FormStatus.error) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Something went wrong')),
          );
        }
      },
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                TitleRow(
                  title: title,
                  onClose: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 20),
                const SectionLabel(text: 'TIMER NAME'),
                const SizedBox(height: 8),
                const FormNameField(),
                const SizedBox(height: 20),
                const SectionLabel(text: 'ACTIVITY TYPE'),
                const SizedBox(height: 8),
                const ActivityTypeChips(),
                const SizedBox(height: 20),
                const SectionLabel(text: 'FOCUS DURATION'),
                const SizedBox(height: 8),
                const FocusDurationChips(),
                const SizedBox(height: 20),
                const SectionLabel(text: 'BREAK DURATION'),
                const SizedBox(height: 8),
                const BreakDurationChips(),
                const SizedBox(height: 20),
                const SectionLabel(text: 'SESSIONS PER SIT'),
                const SizedBox(height: 8),
                const FormSessionsCounter(),
                const SizedBox(height: 28),
                FormConfirmButton(isEdit: isEdit),
                if (isEdit) ...[
                  const SizedBox(height: 10),
                  const FormDeleteButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Cubit-connected form widgets ─────────────────────────────────────────────

const _kActivityTypes = [
  ('studying', 'Studying'),
  ('coding', 'Coding'),
  ('reading', 'Reading'),
  ('exercise', 'Exercise'),
  ('research', 'Research'),
  ('other', 'Other'),
];

const _kFocusOptions = [
  (900, '15 min'),
  (1500, '25 min'),
  (2700, '45 min'),
  (3600, '1 hr'),
];

const _kBreakOptions = [
  (300, '5 min'),
  (600, '10 min'),
  (900, '15 min'),
];

class FormNameField extends StatefulWidget {
  const FormNameField({super.key});

  @override
  State<FormNameField> createState() => _FormNameFieldState();
}

class _FormNameFieldState extends State<FormNameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: context.read<TimerFormCubit>().state.name);
    _controller.addListener(
      () => context.read<TimerFormCubit>().nameChanged(_controller.text),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NameField(controller: _controller);
}

class ActivityTypeChips extends StatelessWidget {
  const ActivityTypeChips({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context
        .select<TimerFormCubit, String>((c) => c.state.activityType);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kActivityTypes
          .map((t) => PresetPill(
                label: t.$2,
                selected: selected == t.$1,
                onTap: () =>
                    context.read<TimerFormCubit>().activityTypeSelected(t.$1),
              ))
          .toList(),
    );
  }
}

class FocusDurationChips extends StatelessWidget {
  const FocusDurationChips({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context
        .select<TimerFormCubit, int>((c) => c.state.focusDuration);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kFocusOptions
          .map((o) => PresetPill(
                label: o.$2,
                selected: selected == o.$1,
                onTap: () => context
                    .read<TimerFormCubit>()
                    .focusDurationSelected(o.$1),
              ))
          .toList(),
    );
  }
}

class BreakDurationChips extends StatelessWidget {
  const BreakDurationChips({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context
        .select<TimerFormCubit, int>((c) => c.state.breakDuration);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kBreakOptions
          .map((o) => PresetPill(
                label: o.$2,
                selected: selected == o.$1,
                onTap: () => context
                    .read<TimerFormCubit>()
                    .breakDurationSelected(o.$1),
              ))
          .toList(),
    );
  }
}

class FormSessionsCounter extends StatelessWidget {
  const FormSessionsCounter({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = context
        .select<TimerFormCubit, int>((c) => c.state.sessionsPerSit);
    return SessionsCounter(
      value: sessions,
      onDecrement: sessions > 1
          ? () => context.read<TimerFormCubit>().sessionsDecremented()
          : null,
      onIncrement: sessions < 8
          ? () => context.read<TimerFormCubit>().sessionsIncremented()
          : null,
    );
  }
}

class FormConfirmButton extends StatelessWidget {
  final bool isEdit;
  const FormConfirmButton({super.key, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TimerFormCubit>().state;
    final isSaving = state.status == FormStatus.saving;
    return ConfirmButton(
      onPressed: state.isValid && !isSaving
          ? () => isEdit
              ? context.read<TimerFormCubit>().submitEdit()
              : context.read<TimerFormCubit>().submitNew()
          : null,
    );
  }
}

class FormDeleteButton extends StatelessWidget {
  const FormDeleteButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<TimerFormCubit, bool>(
        (c) => c.state.status == FormStatus.saving);
    return Center(
      child: TextButton(
        onPressed: isSaving ? null : () => _confirmDelete(context),
        child: Text(
          'Delete timer',
          style: TextStyle(color: Colors.red.shade400, fontSize: 13),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final cubit = context.read<TimerFormCubit>();
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete timer?',
            style: GoogleFonts.openSans(fontWeight: FontWeight.w600)),
        content: const Text('This timer will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) cubit.deleteTimer();
    });
  }
}
