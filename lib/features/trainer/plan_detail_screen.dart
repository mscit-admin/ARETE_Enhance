import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/trainer_plan.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_label.dart';

/// Read-only view of a plan and its exercises. Shared by the trainer (their
/// own plans) and the trainee (an assigned plan).
class PlanDetailScreen extends StatelessWidget {
  const PlanDetailScreen({super.key, required this.plan});

  final TrainerPlan plan;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: Text(plan.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg,
              AppSpacing.screen, AppSpacing.xxxl),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(l.plansDaysWeeks(plan.daysPerWeek, plan.weeks),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13)),
                  if (plan.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(plan.description,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            height: 1.5)),
                  ],
                  if (plan.coachName != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(l.coachPlanBy(plan.coachName!),
                        style: const TextStyle(
                            color: AppColors.brandGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionLabel(l.planExercisesSection),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < plan.exercises.length; i++) ...[
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${i + 1}',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: p.muted,
                              fontSize: 13)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(plan.exercises[i].name,
                          style: context.textStyles.titleMedium),
                    ),
                    Text(
                      l.planSetsReps(
                          plan.exercises[i].sets, plan.exercises[i].reps),
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: p.text),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}
