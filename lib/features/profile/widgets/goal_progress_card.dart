import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/l10n/enum_labels.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/member.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/progress_bar.dart';

/// Shows the member's goal and their weekly session progress.
class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({super.key, required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.goalWeeklyTarget, style: context.textStyles.titleMedium),
              Text(
                l.goalSessions(member.sessionsThisWeek, member.weeklyTargetSessions),
                style: context.textStyles.bodySmall?.copyWith(color: p.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppProgressBar(value: member.weeklyProgress),
          const SizedBox(height: AppSpacing.md),
          Text(
            member.weeklyProgress >= 1
                ? l.goalHit
                : l.goalRemaining(member.weeklyTargetSessions - member.sessionsThisWeek, member.goal.localized(l)),
            style: context.textStyles.bodySmall?.copyWith(color: p.muted),
          ),
        ],
      ),
    );
  }
}
