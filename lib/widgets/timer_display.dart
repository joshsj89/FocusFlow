import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class TimerDisplay extends StatelessWidget {
  final String timeLabel;
  final double progress;
  final bool isPlaying;

  const TimerDisplay({
    super.key,
    required this.timeLabel,
    this.progress = 1.0,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 210;
    const double strokeWidth = 10;
    const double innerSize = size - strokeWidth * 2 - 6;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: isPlaying ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      builder: (context, t, _) {
        final ringColor = Color.lerp(AppColors.purple, AppColors.teal, t)!;
        final textColor = Color.lerp(AppColors.darkNavy, AppColors.teal, t)!;
        final fillColor = Color.lerp(AppColors.timerInnerFill, const Color(0xFFB8E8E8), t)!;

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
                  valueColor: AlwaysStoppedAnimation(ringColor),
                  backgroundColor: AppColors.cardBorder,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Container(
                width: innerSize,
                height: innerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fillColor,
                ),
                child: Center(
                  child: Text(
                    timeLabel,
                    style: GoogleFonts.openSans(
                      fontSize: 38,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
