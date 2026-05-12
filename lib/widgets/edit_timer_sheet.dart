import 'package:flutter/material.dart';
import 'package:focusflow/widgets/timer_sheet_widgets.dart';


class EditTimerSheet extends StatefulWidget {
  const EditTimerSheet({super.key});

  @override
  State<EditTimerSheet> createState() => _EditTimerSheetState();
}

class _EditTimerSheetState extends State<EditTimerSheet> {
  final _nameController = TextEditingController();
  final _customDurationController = TextEditingController();
  int? _selectedPreset = 25;
  int _sessions = 2;

  static const _presets = [15, 25, 45];

  @override
  void dispose() {
    _nameController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  void _selectPreset(int mins) {
    setState(() {
      _selectedPreset = mins;
      _customDurationController.clear();
    });
  }

  void _onCustomDurationChanged(String value) {
    setState(() {
      _selectedPreset = null;
    });
  }

  int get _effectiveDuration {
    if (_selectedPreset != null) return _selectedPreset!;
    return int.tryParse(_customDurationController.text) ?? 0;
  }

  void _confirm() {
    final name = _nameController.text.trim();
    final duration = _effectiveDuration;
    if (name.isEmpty || duration <= 0) return;
    Navigator.of(context).pop({'name': name, 'duration': duration, 'sessions': _sessions});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TitleRow(title: 'Edit Timer',onClose: () => Navigator.of(context).pop()),
            const SizedBox(height: 20),
            SectionLabel(text: 'Timer name'),
            const SizedBox(height: 8),
            NameField(controller: _nameController),
            const SizedBox(height: 20),
            SectionLabel(text: 'Focus duration'),
            const SizedBox(height: 10),
            DurationRow(
              presets: _presets,
              selectedPreset: _selectedPreset,
              customController: _customDurationController,
              onSelectPreset: _selectPreset,
              onCustomChanged: _onCustomDurationChanged,
            ),
            const SizedBox(height: 20),
            SectionLabel(text: 'Sessions per set'),
            const SizedBox(height: 10),
            SessionsCounter(
              value: _sessions,
              onDecrement: _sessions > 1 ? () => setState(() => _sessions--) : null,
              onIncrement: () => setState(() => _sessions++),
            ),
            const SizedBox(height: 24),
            ConfirmButton(onPressed: _confirm),
          ],
        ),
      ),
    );
  }
}