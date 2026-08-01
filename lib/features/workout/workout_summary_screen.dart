import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/workout_session.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pill.dart';
import '../../shared/widgets/section_label.dart';
import '../../shared/widgets/stat_tile.dart';
import '../../state/workout_controller.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  const WorkoutSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.read<WorkoutController>();
    final l = AppLocalizations.of(context);
    final session = c.session;
    if (session == null) {
      return Scaffold(body: Center(child: Text(l.workoutNoSession)));
    }
    final p = context.palette;
    final elapsed = c.elapsed;
    final mins = elapsed.inMinutes;
    final secs = elapsed.inSeconds % 60;

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0,
              AppSpacing.screen, AppSpacing.xxxl),
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                    color: AppColors.teal, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 44),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l.workoutSessionComplete,
                textAlign: TextAlign.center,
                style: context.textStyles.headlineSmall),
            const SizedBox(height: 4),
            Text(session.title,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyMedium?.copyWith(color: p.muted)),
            const SizedBox(height: AppSpacing.xl),

            AppCard(
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatTile(
                      value: '$mins:${secs.toString().padLeft(2, '0')}',
                      label: l.workoutStatDuration),
                  StatTile(
                      value: '${session.completedSets}', label: l.workoutStatSets),
                  StatTile(
                      value: _fmtVolume(session.totalVolume),
                      unit: 'kg',
                      label: l.workoutStatVolume),
                  StatTile(
                      value: '${session.prCount}',
                      label: l.workoutStatPrs,
                      valueColor: AppColors.teal),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            SectionLabel(l.workoutByExercise),
            const SizedBox(height: AppSpacing.sm),
            for (final e in session.exercises) _ExerciseSummary(exercise: e),

            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
              child: Text(l.actionDone),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtVolume(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _ExerciseSummary extends StatelessWidget {
  const _ExerciseSummary({required this.exercise});
  final WorkoutExercise exercise;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final sets = exercise.loggedSets;
    final hasPr = sets.any((s) => s.isPr);
    final top = sets.isEmpty
        ? null
        : sets.reduce((a, b) => a.volume >= b.volume ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.exercise.name,
                    style: context.textStyles.titleMedium),
                Text(
                  sets.isEmpty
                      ? l.workoutSkipped
                      : (top != null
                          ? l.workoutSetsTop(sets.length,
                              top.weightKg.toStringAsFixed(top.weightKg % 1 == 0 ? 0 : 1),
                              top.reps)
                          : l.workoutSetsOnly(sets.length)),
                  style:
                      context.textStyles.bodySmall?.copyWith(color: p.muted),
                ),
              ],
            ),
          ),
          if (hasPr) Pill(l.prShort, tone: PillTone.teal),
        ],
      ),
    );
  }
}
