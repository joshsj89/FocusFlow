import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/music_service.dart';
import '../theme/app_colors.dart';
import 'animated_press.dart';

class SoundSelectorBar extends StatelessWidget {
  final VoidCallback? onTap;

  const SoundSelectorBar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MusicService.instance,
      builder: (context, _) {
        final service = MusicService.instance;
        final trackName = service.currentTrack?.displayName ?? 'No Sound';
        final hasTrack = service.currentTrack != null;

        return AnimatedPress(
          onTap: onTap,
          pressedScale: 0.97,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.purple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  hasTrack ? Icons.music_note_rounded : Icons.music_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                Expanded(
                  child: Text(
                    trackName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.openSans(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.expand_more_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
