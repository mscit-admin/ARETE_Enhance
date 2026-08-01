import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

/// A large numeric value with − / + buttons, used for weight and reps entry.
class StepperField extends StatelessWidget {
  const StepperField({
    super.key,
    required this.value,
    required this.label,
    required this.onDecrement,
    required this.onIncrement,
    this.color,
  });

  final String value;
  final String label;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundButton(icon: Icons.remove, onTap: onDecrement),
            SizedBox(
              width: 84,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: color ?? p.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            _RoundButton(icon: Icons.add, onTap: onIncrement),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: p.muted,
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surfaceAlt,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(icon, size: 22, color: p.text),
        ),
      ),
    );
  }
}
