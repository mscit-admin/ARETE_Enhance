import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

/// Horizontally scrolling achievement badges earned by the member.
class BadgesRow extends StatelessWidget {
  const BadgesRow({super.key, required this.badges});

  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (badges.isEmpty) {
      return Text(
        'No badges yet — your first workout earns one.',
        style: context.textStyles.bodySmall?.copyWith(color: p.muted),
      );
    }
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) {
          return Container(
            width: 96,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: p.line),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.military_tech,
                    color: AppColors.gold, size: 30),
                const SizedBox(height: 6),
                Text(
                  badges[i],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: p.text,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
