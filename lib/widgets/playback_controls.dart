import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'animated_press.dart';

class PlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onRewind;
  final VoidCallback onPause;

  const PlaybackControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onRewind,
    required this.onPause,
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
          icon: Icons.play_arrow,
          size: 58,
          onTap: onPlayPause,
        ),
        const SizedBox(width: 20),
        _OutlinedControlButton(
          icon: Icons.pause,
          size: 48,
          onTap: onPause,
        ),
      ],
    );
  }
}

class _OutlinedControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _OutlinedControlButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.purple, width: 1.5),
        ),
        child: Icon(icon, color: AppColors.purple, size: size * 0.44),
      ),
    );
  }
}

class _FilledControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _FilledControlButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.purple,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.48),
      ),
    );
  }
}
