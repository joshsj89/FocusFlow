import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/timer_profile.dart';
import '../theme/app_colors.dart';
import 'animated_press.dart';
import 'edit_timer_sheet.dart';

class TimerCard extends StatelessWidget {
  final TimerProfile timer;
  final bool isActive;
  final VoidCallback? onTap;

  const TimerCard({
    super.key,
    required this.timer,
    this.isActive = false,
    this.onTap,
  });

  void _openEdit(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditTimerSheet(timer: timer),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      pressedScale: 0.97,
      onTap: onTap ?? () => _openEdit(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.only(left: 16, top: 14, bottom: 14, right: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.04),
              blurRadius: 6,
              offset: Offset(0, 2),
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
                    timer.name,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${timer.focusDuration ~/ 60} mins • ${timer.sessionsPerSit} sessions',
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: AppColors.subtitleText,
                    ),
                  ),
                ],
              ),
            ),
            // Edit icon — always accessible regardless of tap mode
            GestureDetector(
              onTap: () => _openEdit(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: isActive
                      ? AppColors.purple
                      : AppColors.subtitleText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
