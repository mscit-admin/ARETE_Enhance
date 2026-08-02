import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

enum PillTone { ember, teal, neutral, gold }

/// A small status pill (e.g. "Active", "PR", "Gold Member").
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.tone = PillTone.neutral, this.icon});

  final String label;
  final PillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    late Color bg;
    late Color fg;
    switch (tone) {
      case PillTone.ember:
        // Carbon: the primary pill is lime, not ember.
        bg = AppColors.limeTintBg;
        fg = AppColors.accent;
      case PillTone.teal:
        bg = p.tealSoft;
        fg = AppColors.teal;
      case PillTone.gold:
        bg = AppColors.gold.withValues(alpha: 0.16);
        fg = AppColors.gold;
      case PillTone.neutral:
        bg = p.surfaceAlt;
        fg = p.muted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
