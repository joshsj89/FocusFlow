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
                // Required field indicator
                Row(children: [
                  const SectionLabel(text: 'TIMER NAME'),
                  Text(' *', style: GoogleFonts.openSans(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: Colors.red.shade400,
                  )),
                ]),
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
  Widget build(BuildContext context) {
    final showError = context
        .select<TimerFormCubit, bool>((c) => c.state.showNameError);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NameField(controller: _controller),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'A title is required',
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: Colors.red.shade400,
              ),
            ),
          ),
      ],
    );
  }
}

class ActivityTypeChips extends StatelessWidget {
  const ActivityTypeChips({super.key});

  @override
  Widget build(BuildContext context) {
    final activityType = context
        .select<TimerFormCubit, String>((c) => c.state.activityType);
    final isCustom = context
        .select<TimerFormCubit, bool>((c) => c.state.activityIsCustom);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Preset activity chips — deselected when custom is active
            ..._kActivityTypes
                .where((t) => t.$1 != 'other')
                .map((t) => PresetPill(
                      label: t.$2,
                      selected: !isCustom && activityType == t.$1,
                      onTap: () => context
                          .read<TimerFormCubit>()
                          .activityTypeSelected(t.$1),
                    )),
            // Other chip — activates custom name input
            PresetPill(
              label: 'Other',
              selected: isCustom,
              onTap: () =>
                  context.read<TimerFormCubit>().activityTypeSelected('other'),
            ),
          ],
        ),
        if (isCustom) ...[
          const SizedBox(height: 10),
          _CustomActivityField(),
        ],
      ],
    );
  }
}

class _CustomActivityField extends StatefulWidget {
  const _CustomActivityField();

  @override
  State<_CustomActivityField> createState() => _CustomActivityFieldState();
}

class _CustomActivityFieldState extends State<_CustomActivityField> {
  late final TextEditingController _controller;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: context.read<TimerFormCubit>().state.activityType);
    _controller.addListener(() {
      setState(() => _touched = true);
      context.read<TimerFormCubit>().customActivityNameChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showError = _touched && _controller.text.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          maxLength: 30,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.openSans(fontSize: 14, color: AppColors.darkNavy),
          decoration: InputDecoration(
            hintText: 'Name your activity…',
            hintStyle: GoogleFonts.openSans(
                fontSize: 13, color: AppColors.subtitleText),
            counterText: '',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: showError ? Colors.red.shade300 : AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: showError ? Colors.red.shade400 : AppColors.teal,
                  width: 1.5),
            ),
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Activity name is required',
              style: GoogleFonts.openSans(
                  fontSize: 12, color: Colors.red.shade400),
            ),
          ),
      ],
    );
  }
}

class FocusDurationChips extends StatelessWidget {
  const FocusDurationChips({super.key});

  @override
  Widget build(BuildContext context) {
    final focusDuration =
        context.select<TimerFormCubit, int>((c) => c.state.focusDuration);
    final isCustom = context
        .select<TimerFormCubit, bool>((c) => c.state.focusDurationIsCustom);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._kFocusOptions.map((o) => PresetPill(
                  label: o.$2,
                  selected: !isCustom && focusDuration == o.$1,
                  onTap: () => context
                      .read<TimerFormCubit>()
                      .focusDurationSelected(o.$1),
                )),
            PresetPill(
              label: 'Custom',
              selected: isCustom,
              onTap: () => context
                  .read<TimerFormCubit>()
                  .focusDurationCustomActivated(),
            ),
          ],
        ),
        if (isCustom) ...[
          const SizedBox(height: 10),
          _CustomFocusPicker(),
        ],
      ],
    );
  }
}

class _CustomFocusPicker extends StatefulWidget {
  const _CustomFocusPicker();

  @override
  State<_CustomFocusPicker> createState() => _CustomFocusPickerState();
}

class _CustomFocusPickerState extends State<_CustomFocusPicker> {
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _minsCtrl;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    final current = context.read<TimerFormCubit>().state.focusDuration;
    _hoursCtrl = TextEditingController(text: (current ~/ 3600).toString());
    _minsCtrl =
        TextEditingController(text: ((current % 3600) ~/ 60).toString());
    _hoursCtrl.addListener(_onChanged);
    _minsCtrl.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() => _touched = true);
    final hours = int.tryParse(_hoursCtrl.text) ?? 0;
    final mins = (int.tryParse(_minsCtrl.text) ?? 0).clamp(0, 59);
    context.read<TimerFormCubit>().customFocusDurationSet(hours, mins);
  }

  @override
  void dispose() {
    _hoursCtrl.dispose();
    _minsCtrl.dispose();
    super.dispose();
  }

  bool get _isZero {
    final hours = int.tryParse(_hoursCtrl.text) ?? 0;
    final mins = int.tryParse(_minsCtrl.text) ?? 0;
    return hours == 0 && mins == 0;
  }

  @override
  Widget build(BuildContext context) {
    final showError = _touched && _isZero;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: _TimeField(
                    controller: _hoursCtrl, label: 'hrs', max: 8,
                    hasError: showError)),
            const SizedBox(width: 12),
            Expanded(
                child: _TimeField(
                    controller: _minsCtrl, label: 'min', max: 59,
                    hasError: showError)),
          ],
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Duration must be greater than 0',
              style: GoogleFonts.openSans(
                  fontSize: 12, color: Colors.red.shade400),
            ),
          ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int max;
  final bool hasError;

  const _TimeField({
    required this.controller,
    required this.label,
    required this.max,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: GoogleFonts.openSans(fontSize: 15, color: AppColors.darkNavy),
      decoration: InputDecoration(
        hintText: '0',
        suffixText: label,
        suffixStyle:
            GoogleFonts.openSans(fontSize: 13, color: AppColors.subtitleText),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: hasError ? Colors.red.shade300 : AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: hasError ? Colors.red.shade400 : AppColors.teal,
              width: 1.5),
        ),
      ),
      onChanged: (v) {
        final n = int.tryParse(v);
        if (n != null && n > max) {
          controller.text = max.toString();
          controller.selection =
              TextSelection.collapsed(offset: controller.text.length);
        }
      },
    );
  }
}

class BreakDurationChips extends StatelessWidget {
  const BreakDurationChips({super.key});

  @override
  Widget build(BuildContext context) {
    final breakDuration =
        context.select<TimerFormCubit, int>((c) => c.state.breakDuration);
    final isCustom = context
        .select<TimerFormCubit, bool>((c) => c.state.breakDurationIsCustom);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._kBreakOptions.map((o) => PresetPill(
                  label: o.$2,
                  selected: !isCustom && breakDuration == o.$1,
                  onTap: () => context
                      .read<TimerFormCubit>()
                      .breakDurationSelected(o.$1),
                )),
            PresetPill(
              label: 'Custom',
              selected: isCustom,
              onTap: () => context
                  .read<TimerFormCubit>()
                  .breakDurationCustomActivated(),
            ),
          ],
        ),
        if (isCustom) ...[
          const SizedBox(height: 10),
          _CustomBreakPicker(),
        ],
      ],
    );
  }
}

class _CustomBreakPicker extends StatefulWidget {
  const _CustomBreakPicker();

  @override
  State<_CustomBreakPicker> createState() => _CustomBreakPickerState();
}

class _CustomBreakPickerState extends State<_CustomBreakPicker> {
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _minsCtrl;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    final current = context.read<TimerFormCubit>().state.breakDuration;
    _hoursCtrl = TextEditingController(text: (current ~/ 3600).toString());
    _minsCtrl =
        TextEditingController(text: ((current % 3600) ~/ 60).toString());
    _hoursCtrl.addListener(_onChanged);
    _minsCtrl.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() => _touched = true);
    final hours = int.tryParse(_hoursCtrl.text) ?? 0;
    final mins = (int.tryParse(_minsCtrl.text) ?? 0).clamp(0, 59);
    context.read<TimerFormCubit>().customBreakDurationSet(hours, mins);
  }

  @override
  void dispose() {
    _hoursCtrl.dispose();
    _minsCtrl.dispose();
    super.dispose();
  }

  bool get _isZero {
    final hours = int.tryParse(_hoursCtrl.text) ?? 0;
    final mins = int.tryParse(_minsCtrl.text) ?? 0;
    return hours == 0 && mins == 0;
  }

  @override
  Widget build(BuildContext context) {
    final showError = _touched && _isZero;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: _TimeField(
                    controller: _hoursCtrl,
                    label: 'hrs',
                    max: 2,
                    hasError: showError)),
            const SizedBox(width: 12),
            Expanded(
                child: _TimeField(
                    controller: _minsCtrl,
                    label: 'min',
                    max: 59,
                    hasError: showError)),
          ],
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Duration must be greater than 0',
              style: GoogleFonts.openSans(
                  fontSize: 12, color: Colors.red.shade400),
            ),
          ),
      ],
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
    final enabled = state.isValid && !isSaving;
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: ConfirmButton(
        onPressed: enabled
            ? () => isEdit
                ? context.read<TimerFormCubit>().submitEdit()
                : context.read<TimerFormCubit>().submitNew()
            : null,
      ),
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
