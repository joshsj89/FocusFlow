import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/timer_profile.dart';
import '../services/timer_service.dart';
import 'timer_sheet_widgets.dart';

class EditTimerSheet extends StatefulWidget {
  final TimerProfile timer;

  const EditTimerSheet({super.key, required this.timer});

  @override
  State<EditTimerSheet> createState() => _EditTimerSheetState();
}

class _EditTimerSheetState extends State<EditTimerSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _customDurationController;
  late int? _selectedPreset;
  late int _sessions;
  bool _saving = false;
  String? _errorMessage;

  static const _presets = [15, 25, 45];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.timer.name);
    _sessions = widget.timer.sessionsPerSit;
    final durationMins = widget.timer.focusDuration ~/ 60;
    if (_presets.contains(durationMins)) {
      _selectedPreset = durationMins;
      _customDurationController = TextEditingController();
    } else {
      _selectedPreset = null;
      _customDurationController =
          TextEditingController(text: durationMins.toString());
    }
  }

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
      await TimerService.updateTimer(
        uid,
        widget.timer.copyWith(
            name: name,
            focusDuration: duration * 60,
            sessionsPerSit: _sessions),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete timer?'),
        content: Text('"${widget.timer.name}" will be permanently deleted.'),
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
    );
    if (confirmed != true) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await TimerService.deleteTimer(uid, widget.timer.id);
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
              title: 'Edit Timer',
              onClose: () => Navigator.of(context).pop(),
            ),
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
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _saving ? null : _delete,
                child: Text(
                  'Delete timer',
                  style: TextStyle(color: Colors.red.shade400, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
