import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focusflow/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'animated_press.dart';

class TitleRow extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const TitleRow({super.key, required this.title, required this.onClose,});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
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

class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel({super.key, required this.text});

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

class NameField extends StatelessWidget {
  final TextEditingController controller;

  const NameField({super.key, required this.controller});

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

class DurationRow extends StatelessWidget {
  final List<int> presets;
  final int? selectedPreset;
  final TextEditingController customController;
  final ValueChanged<int> onSelectPreset;
  final ValueChanged<String> onCustomChanged;

  const DurationRow({
    super.key,
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
              child: PresetPill(
                label: '$mins mins',
                selected: selected,
                onTap: () => onSelectPreset(mins),
              ),
            ),
          );
        }),
        Expanded(
          child: CustomPill(
            controller: customController,
            isActive: selectedPreset == null && customController.text.isNotEmpty,
            onChanged: onCustomChanged,
          ),
        ),
      ],
    );
  }
}

class PresetPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PresetPill({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: onTap,
      pressedScale: 0.95,
      hoveredScale: 1.02,
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

class CustomPill extends StatelessWidget {
  final TextEditingController controller;
  final bool isActive;
  final ValueChanged<String> onChanged;

  const CustomPill({
    super.key,
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

class SessionsCounter extends StatelessWidget {
  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  const SessionsCounter({
    super.key,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CounterButton(
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
        CounterButton(
          icon: Icons.keyboard_arrow_up_rounded,
          onPressed: onIncrement,
        ),
      ],
    );
  }
}

class CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const CounterButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: onPressed,
      child: Icon(
        icon,
        size: 28,
        color: onPressed != null ? AppColors.darkNavy : AppColors.dotEmpty,
      ),
    );
  }
}

class ConfirmButton extends StatefulWidget {
  final VoidCallback onPressed;

  const ConfirmButton({super.key, required this.onPressed});

  @override
  State<ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<ConfirmButton> {
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
          ),
        ),
      ),
    );
  }
}
