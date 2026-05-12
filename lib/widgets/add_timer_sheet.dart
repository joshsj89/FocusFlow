import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

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
            _TitleRow(onClose: () => Navigator.of(context).pop()),
            const SizedBox(height: 20),
            _SectionLabel('Timer name'),
            const SizedBox(height: 8),
            _NameField(controller: _nameController),
            const SizedBox(height: 20),
            _SectionLabel('Focus duration'),
            const SizedBox(height: 10),
            _DurationRow(
              presets: _presets,
              selectedPreset: _selectedPreset,
              customController: _customDurationController,
              onSelectPreset: _selectPreset,
              onCustomChanged: _onCustomDurationChanged,
            ),
            const SizedBox(height: 20),
            _SectionLabel('Sessions per set'),
            const SizedBox(height: 10),
            _SessionsCounter(
              value: _sessions,
              onDecrement: _sessions > 1 ? () => setState(() => _sessions--) : null,
              onIncrement: () => setState(() => _sessions++),
            ),
            const SizedBox(height: 24),
            _ConfirmButton(onPressed: _confirm),
          ],
        ),
      ),
    );
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
          'New Timer',
          style: GoogleFonts.openSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.darkNavy,
          ),
        ),
        const Spacer(),
        GestureDetector(
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

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.openSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.subtitleText,
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;

  const _NameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.openSans(fontSize: 14, color: AppColors.darkNavy),
      decoration: InputDecoration(
        hintText: 'e.g. Study, Focus, Design...',
        hintStyle: GoogleFonts.openSans(fontSize: 13, color: AppColors.subtitleText),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
      ),
    );
  }
}

class _DurationRow extends StatelessWidget {
  final List<int> presets;
  final int? selectedPreset;
  final TextEditingController customController;
  final ValueChanged<int> onSelectPreset;
  final ValueChanged<String> onCustomChanged;

  const _DurationRow({
    required this.presets,
    required this.selectedPreset,
    required this.customController,
    required this.onSelectPreset,
    required this.onCustomChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...presets.map((mins) {
          final selected = selectedPreset == mins;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _PresetPill(
                label: '$mins mins',
                selected: selected,
                onTap: () => onSelectPreset(mins),
              ),
            ),
          );
        }),
        Expanded(
          child: _CustomPill(
            controller: customController,
            isActive: selectedPreset == null && customController.text.isNotEmpty,
            onChanged: onCustomChanged,
          ),
        ),
      ],
    );
  }
}

class _PresetPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.purple : AppColors.cardBorder,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
          color: selected ? AppColors.purple.withAlpha(20) : Colors.transparent,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.purple : AppColors.darkNavy,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomPill extends StatelessWidget {
  final TextEditingController controller;
  final bool isActive;
  final ValueChanged<String> onChanged;

  const _CustomPill({
    required this.controller,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive ? AppColors.purple : AppColors.cardBorder,
          width: isActive ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(20),
        color: isActive ? AppColors.purple.withAlpha(20) : Colors.transparent,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(fontSize: 11, color: AppColors.darkNavy),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                hintText: '--',
              ),
            ),
          ),
          Text(
            'mins',
            style: GoogleFonts.openSans(fontSize: 11, color: AppColors.subtitleText),
          ),
        ],
      ),
    );
  }
}

class _SessionsCounter extends StatelessWidget {
  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  const _SessionsCounter({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CounterButton(
          icon: Icons.keyboard_arrow_down_rounded,
          onPressed: onDecrement,
        ),
        const SizedBox(width: 10),
        Text(
          '$value',
          style: GoogleFonts.openSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkNavy,
          ),
        ),
        const SizedBox(width: 10),
        _CounterButton(
          icon: Icons.keyboard_arrow_up_rounded,
          onPressed: onIncrement,
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CounterButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Icon(
        icon,
        size: 28,
        color: onPressed != null ? AppColors.darkNavy : AppColors.dotEmpty,
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ConfirmButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.teal, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          foregroundColor: AppColors.teal,
          backgroundColor: AppColors.timerInnerFill,
        ),
        child: Text(
          'Confirm',
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
