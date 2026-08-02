import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/starter_plan.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import 'assessment_flow_screen.dart';

/// Read-only view of the self-guided starter plan the assessment recommended.
class StarterPlanDetailScreen extends StatelessWidget {
  const StarterPlanDetailScreen({super.key, required this.plan});

  final StarterPlan plan;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: Text(l.assessYourPlan)),
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
                  Text(l.resultPlanSplitWeeks(plan.split, plan.weeks),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13)),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      _stat('${plan.daysPerWeek}', l.resultStatDaysWk),
                      const SizedBox(width: AppSpacing.xl),
                      _stat('~${plan.avgMinutes}', l.resultStatMin),
                      const SizedBox(width: AppSpacing.xl),
                      _stat('${plan.weeks}', l.resultStatWeeks),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(plan.description,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.teal),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(l.starterAbout,
                        style: context.textStyles.bodySmall
                            ?.copyWith(color: p.muted)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AssessmentFlowScreen()),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l.starterChangePlan),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        Text(label.toUpperCase(),
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8)),
      ],
    );
  }
}
