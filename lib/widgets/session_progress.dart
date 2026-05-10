import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum DotStatus { completed, current, upcoming, skipped }

class SessionProgress extends StatelessWidget {
  final List<DotStatus> dots;
  final String label;

  const SessionProgress({
    super.key,
    required this.dots,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: dots.map(_buildDot).toList(),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 12,
            color: AppColors.subtitleText,
          ),
        ),
      ],
    );
  }

  Widget _buildDot(DotStatus status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: switch (status) {
        DotStatus.completed => Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal,
            ),
          ),
        DotStatus.current => Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.teal, width: 2),
            ),
          ),
        DotStatus.upcoming => Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.dotEmpty, width: 2),
            ),
          ),
        DotStatus.skipped => SizedBox(
            width: 14,
            height: 14,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.dotEmpty, width: 1.5),
                  ),
                ),
                const Icon(Icons.close, size: 8, color: AppColors.dotEmpty),
              ],
            ),
          ),
      },
    );
  }
}
