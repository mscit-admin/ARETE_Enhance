import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/trainer_plan.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_label.dart';
import '../workout/plan_session_screen.dart';

/// View of a plan grouped by day. Shared by the trainer (their own plans) and
/// the trainee (an assigned plan — who also gets a "start session" button).
class PlanDetailScreen extends StatefulWidget {
  const PlanDetailScreen({super.key, required this.plan});

  final TrainerPlan plan;

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  int _selectedDay = 0;

  int get _dayCount {
    var maxDay = widget.plan.daysPerWeek;
    for (final e in widget.plan.exercises) {
      if (e.day + 1 > maxDay) maxDay = e.day + 1;
    }
    return maxDay < 1 ? 1 : maxDay;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final plan = widget.plan;
    final ar = Directionality.of(context) == TextDirection.rtl;
    final isTrainee = plan.coachName != null;
    final dayExercises =
        plan.exercises.where((e) => e.day == _selectedDay).toList();

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

            // ---- Day selector ----
            if (_dayCount > 1) ...[
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dayCount,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final selected = i == _selectedDay;
                    return InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => setState(() => _selectedDay = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.limeTintBg : p.surfaceAlt,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: selected
                                  ? AppColors.limeTintBorder
                                  : p.line),
                        ),
                        child: Text(
                          l.planDay(i + 1),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: selected ? AppColors.accent : p.muted,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            if (dayExercises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child: Text(l.planDayEmpty,
                      style: context.textStyles.bodyMedium
                          ?.copyWith(color: p.muted)),
                ),
              )
            else
              for (var i = 0; i < dayExercises.length; i++) ...[
                _ExerciseRow(index: i + 1, ex: dayExercises[i], arabic: ar),
                const SizedBox(height: AppSpacing.sm),
              ],

            if (isTrainee && dayExercises.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlanSessionScreen(
                        plan: plan, dayIndex: _selectedDay),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l.planStartSession),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.index,
    required this.ex,
    required this.arabic,
  });
  final int index;
  final PlanExercise ex;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final metrics = ex.weight != null && ex.weight! > 0
        ? '${l.planSetsReps(ex.sets, ex.reps)} · ${_fmt(ex.weight!)} ${l.planKg}'
        : l.planSetsReps(ex.sets, ex.reps);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$index',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: p.muted,
                        fontSize: 13)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.label(arabic),
                        style: context.textStyles.titleMedium),
                    if (ex.muscleGroup.isNotEmpty)
                      Text(ex.muscleGroup,
                          style: context.textStyles.bodySmall
                              ?.copyWith(color: p.muted)),
                  ],
                ),
              ),
              Text(metrics,
                  style:
                      TextStyle(fontWeight: FontWeight.w700, color: p.text)),
            ],
          ),
          if (ex.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(ex.notes,
                style: context.textStyles.bodySmall
                    ?.copyWith(color: AppColors.accent)),
          ],
        ],
      ),
    );
  }

  static String _fmt(double d) =>
      d == d.roundToDouble() ? d.toInt().toString() : d.toString();
}
