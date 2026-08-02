import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/l10n/enum_labels.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/assessment.dart';
import '../../l10n/app_localizations.dart';
import '../../state/assessment_controller.dart';
import 'assessment_result_screen.dart';
import 'widgets/choice_tile.dart';

class AssessmentFlowScreen extends StatefulWidget {
  const AssessmentFlowScreen({super.key});

  @override
  State<AssessmentFlowScreen> createState() => _AssessmentFlowScreenState();
}

class _AssessmentFlowScreenState extends State<AssessmentFlowScreen> {
  static const _stepCount = 6;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    // Start each assessment fresh.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<AssessmentController>().reset());
  }

  List<String> _titles(AppLocalizations l) => [
        l.assessTitleGoal,
        l.assessTitleExperience,
        l.assessTitleDays,
        l.assessTitleEquipment,
        l.assessTitleActivity,
        l.assessTitleSafety,
      ];

  bool _canContinue(AssessmentController c) {
    switch (_step) {
      case 0:
        return c.answers.goal != null;
      case 1:
        return c.answers.experience != null;
      case 3:
        return c.answers.equipment.isNotEmpty;
      case 4:
        return c.answers.activity != null;
      default:
        return true;
    }
  }

  void _next(AssessmentController c) {
    if (_step < _stepCount - 1) {
      setState(() => _step++);
    } else {
      c.computeRecommendations(AppLocalizations.of(context));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AssessmentResultScreen()),
      );
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AssessmentController>();
    final p = context.palette;
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: _step == 0
            ? null
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
        title: Text(l.assessStepOf(_step + 1, _stepCount)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                  AppSpacing.sm, AppSpacing.screen, AppSpacing.md),
              child: Row(
                children: [
                  for (var i = 0; i < _stepCount; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _step ? AppColors.accent : p.line,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen),
                children: [
                  Text(_titles(l)[_step],
                      style: context.textStyles.headlineSmall),
                  const SizedBox(height: AppSpacing.lg),
                  _StepBody(step: _step, controller: c),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                  AppSpacing.md, AppSpacing.screen, AppSpacing.lg),
              decoration: BoxDecoration(
                color: p.surface,
                border: Border(top: BorderSide(color: p.line)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canContinue(c) ? () => _next(c) : null,
                  child: Text(
                      _step == _stepCount - 1 ? l.assessSeeMyPlan : l.assessContinue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.step, required this.controller});
  final int step;
  final AssessmentController controller;

  @override
  Widget build(BuildContext context) {
    final a = controller.answers;
    final l = AppLocalizations.of(context);
    switch (step) {
      case 0:
        const emoji = {
          FitnessGoal.loseWeight: '🔥',
          FitnessGoal.buildMuscle: '💪',
          FitnessGoal.endurance: '🏃',
          FitnessGoal.generalFitness: '🎯',
        };
        return Column(
          children: [
            for (final g in FitnessGoal.values)
              ChoiceTile(
                leading: emoji[g],
                label: g.localized(l),
                selected: a.goal == g,
                onTap: () => controller.setGoal(g),
              ),
          ],
        );
      case 1:
        const emoji = {
          ExperienceLevel.beginner: '🌱',
          ExperienceLevel.intermediate: '💪',
          ExperienceLevel.advanced: '🏆',
        };
        final sub = {
          ExperienceLevel.beginner: l.assessExpBeginnerSub,
          ExperienceLevel.intermediate: l.assessExpIntermediateSub,
          ExperienceLevel.advanced: l.assessExpAdvancedSub,
        };
        return Column(
          children: [
            for (final e in ExperienceLevel.values)
              ChoiceTile(
                leading: emoji[e],
                label: e.localized(l),
                subtitle: sub[e],
                selected: a.experience == e,
                onTap: () => controller.setExperience(e),
              ),
          ],
        );
      case 2:
        return Column(
          children: [
            for (final d in [2, 3, 4, 5, 6])
              ChoiceTile(
                label: l.assessDaysPerWeek(d),
                selected: a.daysPerWeek == d,
                onTap: () => controller.setDays(d),
              ),
          ],
        );
      case 3:
        const emoji = {
          EquipmentAccess.bodyweight: '🤸',
          EquipmentAccess.dumbbells: '🏋️',
          EquipmentAccess.fullGym: '🧰',
          EquipmentAccess.bands: '🎗️',
        };
        return Column(
          children: [
            Text(l.assessChooseAllApply,
                style: context.textStyles.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            for (final e in EquipmentAccess.values)
              ChoiceTile(
                multi: true,
                leading: emoji[e],
                label: e.localized(l),
                selected: a.equipment.contains(e),
                onTap: () => controller.toggleEquipment(e),
              ),
          ],
        );
      case 4:
        const emoji = {
          ActivityLevel.sedentary: '🪑',
          ActivityLevel.light: '🚶',
          ActivityLevel.moderate: '🏃',
          ActivityLevel.high: '⚡',
        };
        return Column(
          children: [
            for (final act in ActivityLevel.values)
              ChoiceTile(
                leading: emoji[act],
                label: act.localized(l),
                selected: a.activity == act,
                onTap: () => controller.setActivity(act),
              ),
          ],
        );
      case 5:
      default:
        return _ParqStep(controller: controller);
    }
  }
}

class _ParqStep extends StatelessWidget {
  const _ParqStep({required this.controller});
  final AssessmentController controller;

  List<String> _parq(AppLocalizations l) =>
      [l.parq1, l.parq2, l.parq3, l.parq4, l.parq5, l.parq6];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = controller.answers;
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: p.tealSoft,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.teal),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l.assessParqIntro,
                  style: context.textStyles.bodySmall
                      ?.copyWith(color: AppColors.teal),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < parqQuestions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: a.parq[i],
              activeColor: AppColors.accent,
              title: Text(_parq(l)[i],
                  style: context.textStyles.bodyMedium),
              onChanged: (v) => controller.setParq(i, v),
            ),
          ),
      ],
    );
  }
}
