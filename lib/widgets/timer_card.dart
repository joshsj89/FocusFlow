import 'package:flutter/material.dart';
import 'package:focusflow/widgets/edit_timer_sheet.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'animated_press.dart';

class TimerCard extends StatelessWidget {
  final String title;
  final int durationMins;
  final int sessions;
  final bool isActive;
  // final VoidCallback? onTap;

  const TimerCard({
    super.key,
    required this.title,
    required this.durationMins,
    required this.sessions,
    this.isActive = false,
    // this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      pressedScale: 0.97,
      onTap: () => showDialog(context: context, builder: (_) => const EditTimerSheet()),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppColors.purple : AppColors.dotEmpty,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$durationMins mins • $sessions sessions',
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: AppColors.subtitleText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.subtitleText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
