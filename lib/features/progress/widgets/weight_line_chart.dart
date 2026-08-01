import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A compact line chart with a soft area fill and an emphasised end point.
class WeightLineChart extends StatelessWidget {
  const WeightLineChart({
    super.key,
    required this.values,
    required this.color,
    this.height = 92,
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
          painter: _LinePainter(values: values, color: color, grid: p.line),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.values, required this.color, required this.grid});

  final List<double> values;
  final Color color;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);
    const padTop = 8.0;
    const padBottom = 8.0;
    final chartH = size.height - padTop - padBottom;

    double xFor(int i) => size.width * i / (values.length - 1);
    double yFor(double v) => padTop + chartH * (1 - (v - minV) / range);

    // Faint baseline grid.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var g = 0; g <= 2; g++) {
      final y = padTop + chartH * g / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePath = Path();
    for (var i = 0; i < values.length; i++) {
      final o = Offset(xFor(i), yFor(values[i]));
      if (i == 0) {
        linePath.moveTo(o.dx, o.dy);
      } else {
        linePath.lineTo(o.dx, o.dy);
      }
    }

    // Area fill under the line.
    final areaPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // The line.
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Emphasised end point.
    final endPoint = Offset(xFor(values.length - 1), yFor(values.last));
    canvas.drawCircle(endPoint, 4.5, Paint()..color = color);
    canvas.drawCircle(
      endPoint,
      4.5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.values != values || old.color != color || old.grid != grid;
}
