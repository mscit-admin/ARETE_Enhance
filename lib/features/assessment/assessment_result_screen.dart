import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/starter_plan.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pill.dart';
import '../../shared/widgets/section_label.dart';
import '../../state/assessment_controller.dart';
import '../../state/profile_controller.dart';
import 'plan_matcher.dart';

class AssessmentResultScreen extends StatelessWidget {
  const AssessmentResultScreen({super.key});

  void _choose(BuildContext context, StarterPlan plan) {
    context.read<AssessmentController>().selectPlan(plan);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${plan.name} is now your plan')),
    );
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AssessmentController>();
    final recs = c.recommendations;
    if (recs.isEmpty) {
      return const Scaffold(body: Center(child: Text('No recommendations.')));
    }
    final top = recs.first;
    final alternatives = recs.skip(1).take(2).toList();
    final flagged = c.answers.parqFlagged;

    return Scaffold(
      appBar: AppBar(title: const Text('Your plan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md,
              AppSpacing.screen, AppSpacing.xxxl),
          children: [
            if (flagged) ...[
              _SafetyNotice(),
              const SizedBox(height: AppSpacing.lg),
            ],
            _CalorieEstimate(activity: c.answers.activity),
            const SizedBox(height: AppSpacing.lg),
            const SectionLabel('Recommended for you'),
            const SizedBox(height: AppSpacing.sm),
            _RecommendedCard(
                ranked: top, onStart: () => _choose(context, top.plan)),
            if (alternatives.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const SectionLabel('Alternatives'),
              const SizedBox(height: AppSpacing.sm),
              for (final r in alternatives)
                _AlternativeCard(
                    plan: r.plan, onChoose: () => _choose(context, r.plan)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.health_and_safety_outlined,
              color: AppColors.warning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Based on your answers, check with a doctor before starting a new '
              'program. Your plan is ready when you are.',
              style: context.textStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieEstimate extends StatelessWidget {
  const _CalorieEstimate({required this.activity});
  final ActivityLevel? activity;

  @override
  Widget build(BuildContext context) {
    final member = context.read<ProfileController>().member;
    if (member == null) return const SizedBox.shrink();
    final factor = (activity ?? ActivityLevel.moderate).factor;
    final bmr = member.metrics.bmr(
      ageYears: member.ageYears,
      genderOffset: member.genderBmrOffset,
    );
    final tdee = (bmr * factor).round();
    final p = context.palette;

    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.ember),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('~$tdee kcal / day',
                    style: context.textStyles.titleLarge),
                Text('Estimated maintenance energy for your activity level',
                    style: context.textStyles.bodySmall
                        ?.copyWith(color: p.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.ranked, required this.onStart});
  final RankedPlan ranked;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final plan = ranked.plan;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Pill('Recommended', tone: PillTone.ember),
          const SizedBox(height: AppSpacing.md),
          Text(plan.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('${plan.split} · ${plan.weeks} weeks',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _stat('${plan.daysPerWeek}', 'days/wk'),
              const SizedBox(width: AppSpacing.xl),
              _stat('~${plan.avgMinutes}', 'min'),
              const SizedBox(width: AppSpacing.xl),
              _stat('${plan.weeks}', 'weeks'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(plan.description,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.5)),
          const SizedBox(height: AppSpacing.md),
          for (final reason in ranked.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.teal, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(reason,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              child: const Text('Start this plan'),
            ),
          ),
        ],
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

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({required this.plan, required this.onChoose});
  final StarterPlan plan;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name, style: context.textStyles.titleMedium),
                  Text(
                      '${plan.split} · ${plan.daysPerWeek} days · ${plan.weeks} wks',
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: p.muted)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton(onPressed: onChoose, child: const Text('Choose')),
          ],
        ),
      ),
    );
  }
}
