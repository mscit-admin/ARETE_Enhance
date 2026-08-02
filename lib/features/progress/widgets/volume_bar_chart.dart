import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// A weekly volume bar chart; the most recent bar is emphasised.
class VolumeBarChart extends StatelessWidget {
  const VolumeBarChart({
    super.key,
    required this.values,
    required this.color,
    this.height = 96,
  });

  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) => CustomPaint(
          size: Size(constraints.maxWidth, height),
          painter: _BarPainter(values: values, color: color, track: p.line),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({required this.values, required this.color, required this.track});

  final List<double> values;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final n = values.length;
    final gap = size.width / n * 0.35;
    final barW = size.width / n - gap;
    final radius = Radius.circular(barW * 0.35);

    for (var i = 0; i < n; i++) {
      final x = i * (barW + gap) + gap / 2;
      final h = maxV == 0 ? 0.0 : (values[i] / maxV) * (size.height - 6);
      final isLast = i == n - 1;

      // Ramp each bar from a dim lime up to the bright passed-in color, so the
      // tallest / most-recent bars read brightest. t rises with the bar's
      // value fraction; the last bar is always full bright.
      final frac = maxV == 0 ? 0.0 : values[i] / maxV;
      final t = isLast ? 1.0 : (0.35 + frac * 0.65).clamp(0.35, 1.0);
      final barColor =
          Color.lerp(AppColors.limeTintBorder, color, t) ?? color;

      // Track (full-height faint bar).
      final trackRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, 0, barW, size.height),
        topLeft: radius,
        topRight: radius,
      );
      canvas.drawRRect(trackRect, Paint()..color = track.withValues(alpha: 0.5));

      // Value bar.
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, size.height - h, barW, h),
        topLeft: radius,
        topRight: radius,
      );
      canvas.drawRRect(
        rect,
        Paint()..color = barColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.values != values || old.color != color || old.track != track;
}
