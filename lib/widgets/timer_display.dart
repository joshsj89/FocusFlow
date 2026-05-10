import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class TimerDisplay extends StatelessWidget {
  final String timeLabel;
  final double progress;

  const TimerDisplay({
    super.key,
    required this.timeLabel,
    this.progress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 210;
    const double strokeWidth = 10;
    const double innerSize = size - strokeWidth * 2 - 6;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              valueColor: const AlwaysStoppedAnimation(AppColors.purple),
              backgroundColor: AppColors.cardBorder,
              strokeCap: StrokeCap.round,
            ),
          ),
          Container(
            width: innerSize,
            height: innerSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.timerInnerFill,
            ),
            child: Center(
              child: Text(
                timeLabel,
                style: GoogleFonts.openSans(
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkNavy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
