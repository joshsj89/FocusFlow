import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/timer_service.dart';
import 'timer_sheet_widgets.dart';

class AddTimerSheet extends StatefulWidget {
  const AddTimerSheet({super.key});

  @override
  State<AddTimerSheet> createState() => _AddTimerSheetState();
}

class _AddTimerSheetState extends State<AddTimerSheet> {
  final _nameController = TextEditingController();
  final _customDurationController = TextEditingController();
  int? _selectedPreset = 25;
  int _sessions = 2;
  bool _saving = false;
  String? _errorMessage;

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
    setState(() => _selectedPreset = null);
  }

  int get _effectiveDuration {
    if (_selectedPreset != null) return _selectedPreset!;
    return int.tryParse(_customDurationController.text) ?? 0;
  }

  Future<void> _confirm() async {
    final name = _nameController.text.trim();
    final duration = _effectiveDuration;
    if (name.isEmpty || duration <= 0) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await TimerService.addTimer(uid,
          name: name, focusDuration: duration * 60, sessionsPerSit: _sessions);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
            TitleRow(
                title: 'Add Timer',
                onClose: () => Navigator.of(context).pop()),
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
              onDecrement:
                  _sessions > 1 ? () => setState(() => _sessions--) : null,
              onIncrement: () => setState(() => _sessions++),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            ConfirmButton(onPressed: _saving ? null : _confirm),
          ],
        ),
      ),
    );
  }
}
