import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A single metric readout: a big value with a small uppercase label beneath.
/// Used in the profile metrics strip (weight / BMI / body-fat / weeks).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.valueColor,
    this.unit,
  });

  final String value;
  final String label;
  final Color? valueColor;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: valueColor ?? p.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            children: [
              if (unit != null)
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.muted,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: p.muted,
          ),
        ),
      ],
    );
  }
}
