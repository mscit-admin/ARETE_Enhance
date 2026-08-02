import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// A circular countdown for the rest period between sets.
class RestTimerRing extends StatelessWidget {
  const RestTimerRing({
    super.key,
    required this.remaining,
    required this.progress,
    this.size = 132,
  });

  /// Seconds remaining.
  final int remaining;

  /// 0.0 – 1.0 of rest elapsed remaining (1 = full time left).
  final double progress;

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mins = remaining ~/ 60;
    final secs = remaining % 60;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 9,
              color: p.line,
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 9,
              strokeCap: StrokeCap.round,
              color: AppColors.accent,
              backgroundColor: Colors.transparent,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$mins:${secs.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: p.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'REST LEFT',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: p.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
