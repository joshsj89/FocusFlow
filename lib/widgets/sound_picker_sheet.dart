import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/music_service.dart';
import '../theme/app_colors.dart';

class SoundPickerSheet extends StatefulWidget {
  const SoundPickerSheet({super.key});

  @override
  State<SoundPickerSheet> createState() => _SoundPickerSheetState();
}

class _SoundPickerSheetState extends State<SoundPickerSheet> {
  List<TrackInfo> _tracks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tracks = await MusicService.instance.loadTracks();
    if (mounted) {
      setState(() {
        _tracks = tracks;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = MusicService.instance;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Background Sound',
              style: GoogleFonts.openSans(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.darkNavy,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_tracks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                children: [
                  Icon(Icons.music_off_rounded, color: Colors.grey[400], size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'No music files found.\nDrop .mp3 or .wav files into assets/music/ and rebuild.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.openSans(
                      color: AppColors.subtitleText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            ListenableBuilder(
              listenable: service,
              builder: (context, _) => Column(
                children: [
                  _TrackTile(
                    label: 'None',
                    icon: Icons.volume_off_rounded,
                    isSelected: service.currentTrack == null,
                    onTap: () {
                      service.stop();
                      Navigator.pop(context);
                    },
                  ),
                  ..._tracks.map((t) => _TrackTile(
                        label: t.displayName,
                        icon: Icons.music_note_rounded,
                        isSelected:
                            service.currentTrack?.assetKey == t.assetKey,
                        onTap: () {
                          service.play(t);
                          Navigator.pop(context);
                        },
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TrackTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.purple : Colors.grey[400],
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.openSans(
                  fontSize: 15,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.purple : AppColors.darkNavy,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded, color: AppColors.purple, size: 20),
          ],
        ),
      ),
    );
  }
}
