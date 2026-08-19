import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/assessment_controller.dart';
import 'assessment_flow_screen.dart';
import 'starter_plan_detail_screen.dart';

/// Standalone Assessment screen (a bottom-nav destination). Shows the health
/// assessment entry — opening the flow when no plan is selected yet, or the
/// resulting starter plan once one is.
class AssessmentEntryScreen extends StatelessWidget {
  const AssessmentEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.navAssessment)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg,
              AppSpacing.screen, AppSpacing.xxxl),
          children: const [_AssessmentCard()],
        ),
      ),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard();

  @override
  Widget build(BuildContext context) {
    final assessment = context.watch<AssessmentController>();
    final plan = assessment.selectedPlan;
    final p = context.palette;
    final l = AppLocalizations.of(context);

    return Material(
      color: plan == null ? AppColors.ink : p.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => plan == null
                ? const AssessmentFlowScreen()
                : StarterPlanDetailScreen(plan: plan),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: plan == null ? null : Border.all(color: p.line),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: plan == null
                      ? Colors.white.withValues(alpha: 0.12)
                      : p.emberSoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  plan == null ? Icons.assignment_outlined : Icons.check_circle,
                  color: plan == null ? Colors.white : AppColors.ember,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan == null ? l.assessGetStarter : l.assessYourPlan,
                      style: context.textStyles.titleMedium?.copyWith(
                          color: plan == null ? Colors.white : p.text),
                    ),
                    Text(
                      plan == null ? l.assessTake2min : plan.name,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: plan == null
                            ? Colors.white.withValues(alpha: 0.6)
                            : p.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: plan == null
                      ? Colors.white.withValues(alpha: 0.6)
                      : p.muted),
            ],
          ),
        ),
      ),
    );
  }
}
