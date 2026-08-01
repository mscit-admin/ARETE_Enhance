import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise.dart';
import '../../data/models/set_log.dart';
import '../../data/models/workout_session.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pill.dart';
import '../../shared/widgets/section_label.dart';
import '../../state/workout_controller.dart';
import 'widgets/rest_timer_ring.dart';
import 'widgets/stepper_field.dart';
import 'workout_summary_screen.dart';

class ActiveWorkoutScreen extends StatelessWidget {
  const ActiveWorkoutScreen({super.key});

  Future<void> _finish(BuildContext context) async {
    await context.read<WorkoutController>().finish();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WorkoutSummaryScreen()),
    );
  }

  Future<void> _confirmQuit(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final quit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.workoutFinishTitle),
        content: Text(l.workoutFinishBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.workoutKeepGoing)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.actionFinish)),
        ],
      ),
    );
    if (quit == true && context.mounted) _finish(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<WorkoutController>();
    final session = c.session;
    final we = c.currentExercise;
    if (session == null || we == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final ex = we.exercise;
    final l = AppLocalizations.of(context);
    final setNumber = we.loggedSets.length + 1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ex.name, style: context.textStyles.titleLarge),
            Text(
              l.workoutExerciseSetOf(c.exerciseIndex + 1,
                  session.exercises.length, setNumber.clamp(1, ex.targetSets),
                  ex.targetSets),
              style: context.textStyles.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _confirmQuit(context),
            child: Text(l.actionFinish),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: session.progress,
              minHeight: 4,
              backgroundColor: context.palette.line,
              color: AppColors.ember,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
                  if (c.isResting) ...[
                    _RestSection(controller: c),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _ExerciseInfo(exercise: ex),
                  const SizedBox(height: AppSpacing.lg),
                  if (!we.isComplete) ...[
                    SectionLabel(l.workoutLogThisSet),
                    const SizedBox(height: AppSpacing.sm),
                    _LogSetCard(controller: c, exercise: ex),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  if (we.loggedSets.isNotEmpty) ...[
                    SectionLabel(l.workoutCompletedSets),
                    const SizedBox(height: AppSpacing.sm),
                    _CompletedSets(sets: we.loggedSets, unit: 'kg'),
                  ],
                ],
              ),
            ),
            _BottomBar(
              controller: c,
              onFinish: () => _finish(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestSection extends StatelessWidget {
  const _RestSection({required this.controller});
  final WorkoutController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Pill(l.workoutRest, tone: PillTone.ember),
          ),
          const SizedBox(height: AppSpacing.sm),
          RestTimerRing(
            remaining: controller.restRemaining,
            progress: controller.restProgress,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => controller.addRest(15),
                child: const Text('+15s'),
              ),
              const SizedBox(width: AppSpacing.md),
              OutlinedButton(
                onPressed: controller.skipRest,
                child: Text(l.workoutSkipRest),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExerciseInfo extends StatelessWidget {
  const _ExerciseInfo({required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.slate,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    l.workoutTarget(exercise.targetSets, exercise.targetReps,
                        exercise.restSeconds),
                    style: context.textStyles.bodyMedium),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final cue in exercise.cues)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.surfaceAlt,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(cue,
                            style: context.textStyles.bodySmall
                                ?.copyWith(color: p.muted)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogSetCard extends StatelessWidget {
  const _LogSetCard({required this.controller, required this.exercise});
  final WorkoutController controller;
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final last = exercise.lastWeightKg;
    final diff = last == null ? null : controller.draftWeight - last;

    return AppCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StepperField(
                value: controller.draftWeight
                    .toStringAsFixed(controller.draftWeight % 1 == 0 ? 0 : 1),
                label: 'kg',
                onDecrement: () => controller.adjustWeight(-2.5),
                onIncrement: () => controller.adjustWeight(2.5),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('×',
                    style: TextStyle(fontSize: 22, color: p.muted)),
              ),
              StepperField(
                value: '${controller.draftReps}',
                label: 'reps',
                onDecrement: () => controller.adjustReps(-1),
                onIncrement: () => controller.adjustReps(1),
              ),
            ],
          ),
          if (diff != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              diff == 0
                  ? l.workoutSameAsLast
                  : l.workoutDiffVsLast('${diff > 0 ? '+' : ''}${diff.toStringAsFixed(diff % 1 == 0 ? 0 : 1)}'),
              style: context.textStyles.bodySmall?.copyWith(
                color: diff >= 0 ? AppColors.teal : p.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompletedSets extends StatelessWidget {
  const _CompletedSets({required this.sets, required this.unit});
  final List<SetLog> sets;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Column(
        children: [
          for (final s in sets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                        color: AppColors.teal, shape: BoxShape.circle),
                    child: const Icon(Icons.check,
                        size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(l.workoutSetN(s.setNumber),
                      style: context.textStyles.bodyMedium),
                  const Spacer(),
                  Text(
                    '${s.weightKg.toStringAsFixed(s.weightKg % 1 == 0 ? 0 : 1)} $unit × ${s.reps}',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: p.text,
                        fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                  if (s.isPr) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Pill(l.prShort, tone: PillTone.teal),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.controller, required this.onFinish});
  final WorkoutController controller;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final we = controller.currentExercise!;
    final p = context.palette;
    final l = AppLocalizations.of(context);

    late String label;
    late VoidCallback action;
    if (!we.isComplete) {
      label = controller.isResting ? l.workoutLogSetResting : l.workoutLogSet;
      action = controller.logSet;
    } else if (!controller.isLastExercise) {
      label = l.workoutNextExercise;
      action = controller.nextExercise;
    } else {
      label = l.workoutFinishWorkout;
      action = onFinish;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.lg),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: action,
          child: Text(label),
        ),
      ),
    );
  }
}
