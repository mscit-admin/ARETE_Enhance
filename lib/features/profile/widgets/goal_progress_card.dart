import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/member.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/progress_bar.dart';

/// Shows the member's goal and their weekly session progress.
class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({super.key, required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly target', style: context.textStyles.titleMedium),
              Text(
                '${member.sessionsThisWeek} / ${member.weeklyTargetSessions} sessions',
                style: context.textStyles.bodySmall?.copyWith(color: p.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppProgressBar(value: member.weeklyProgress),
          const SizedBox(height: AppSpacing.md),
          Text(
            member.weeklyProgress >= 1
                ? 'Target hit — strong week. 🔥'
                : '${member.weeklyTargetSessions - member.sessionsThisWeek} session(s) to hit your ${member.goal.label.toLowerCase()} goal this week.',
            style: context.textStyles.bodySmall?.copyWith(color: p.muted),
          ),
        ],
      ),
    );
  }
}
