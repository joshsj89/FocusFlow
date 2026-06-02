import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'animated_press.dart';

class PlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback? onPlayPause;
  final VoidCallback? onRewind;
  final VoidCallback? onSkip;

  const PlaybackControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    this.onRewind,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _OutlinedControlButton(
          icon: Icons.fast_rewind,
          size: 48,
          onTap: onRewind,
        ),
        const SizedBox(width: 20),
        _FilledControlButton(
          isPlaying: isPlaying,
          size: 58,
          onTap: onPlayPause,
        ),
        const SizedBox(width: 20),
        _OutlinedControlButton(
          icon: Icons.skip_next_rounded,
          size: 48,
          onTap: onSkip,
        ),
      ],
    );
  }
}

class _OutlinedControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback? onTap;

  const _OutlinedControlButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: AnimatedPress(
        onTap: onTap ?? () {},
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.purple, width: 1.5),
          ),
          child: Icon(icon, color: AppColors.purple, size: size * 0.44),
        ),
      ),
    );
  }
}

class _FilledControlButton extends StatelessWidget {
  final bool isPlaying;
  final double size;
  final VoidCallback? onTap;

  const _FilledControlButton({
    required this.isPlaying,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: AnimatedPress(
        onTap: onTap ?? () {},
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.purple,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              key: ValueKey(isPlaying),
              color: Colors.white,
              size: size * 0.48,
            ),
          ),
        ),
      ),
    );
  }
}
