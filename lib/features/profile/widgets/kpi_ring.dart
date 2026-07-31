import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// One concentric progress ring: a metric's completion plus its colour.
class RingMetric {
  const RingMetric({required this.progress, required this.color});

  /// 0.0 – 1.0 (values above 1 are clamped when drawn).
  final double progress;
  final Color color;
}

/// A stack of concentric activity rings (outer → inner) with arbitrary content
/// in the centre — used on the home screen to surface daily KPIs.
class KpiRing extends StatelessWidget {
  const KpiRing({
    super.key,
    required this.rings,
    required this.center,
    this.size = 280,
    this.stroke = 13,
    this.gap = 7,
  });

  final List<RingMetric> rings;
  final Widget center;
  final double size;
  final double stroke;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Inset so the centre content clears the innermost ring.
    final contentInset = rings.length * (stroke + gap) + stroke * 0.5;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              rings: rings,
              trackColor: p.line,
              stroke: stroke,
              gap: gap,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(contentInset),
            child: Center(child: center),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.rings,
    required this.trackColor,
    required this.stroke,
    required this.gap,
  });

  final List<RingMetric> rings;
  final Color trackColor;
  final double stroke;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    var radius = (size.width / 2) - (stroke / 2) - 1;

    for (final ring in rings) {
      final track = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = trackColor.withValues(alpha: 0.6)
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius, track);

      final sweep = ring.progress.clamp(0.0, 1.0) * 2 * math.pi;
      if (sweep > 0) {
        final progress = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: -math.pi / 2,
            endAngle: (3 * math.pi) / 2,
            colors: [ring.color.withValues(alpha: 0.75), ring.color],
          ).createShader(Rect.fromCircle(center: center, radius: radius));
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2,
          sweep,
          false,
          progress,
        );
      }
      radius -= stroke + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.rings != rings ||
      old.trackColor != trackColor ||
      old.stroke != stroke ||
      old.gap != gap;
}

/// A compact KPI cell used inside the ring's centre (value + tiny label + icon).
class RingKpiTile extends StatelessWidget {
  const RingKpiTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: p.text,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: p.muted,
          ),
        ),
      ],
    );
  }
}
