import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/workout_session.dart';
import '../../shared/widgets/pill.dart';
import '../../shared/widgets/section_label.dart';
import '../../state/profile_controller.dart';
import '../../state/workout_controller.dart';
import 'active_workout_screen.dart';

/// The Train tab: today's session overview with a Start button.
class WorkoutHomeScreen extends StatefulWidget {
  const WorkoutHomeScreen({super.key});

  @override
  State<WorkoutHomeScreen> createState() => _WorkoutHomeScreenState();
}

class _WorkoutHomeScreenState extends State<WorkoutHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = context.read<WorkoutController>();
      if (c.status == LoadStatus.idle) c.load();
    });
  }

  Future<void> _startWorkout() async {
    final c = context.read<WorkoutController>();
    // Always begin from a fresh, unlogged session.
    await c.load();
    c.start();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WorkoutController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Train')),
      body: SafeArea(
        child: switch (controller.status) {
          LoadStatus.idle || LoadStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          LoadStatus.error =>
            const Center(child: Text('Could not load your workout.')),
          LoadStatus.ready =>
            _Overview(session: controller.session!, onStart: _startWorkout),
        },
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.session, required this.onStart});

  final WorkoutSession session;
  final Future<void> Function() onStart;

  int get _estMinutes {
    var seconds = 0;
    for (final e in session.exercises) {
      seconds += e.exercise.targetSets * (e.exercise.restSeconds + 40);
    }
    return (seconds / 60).round();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.xxxl),
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
              const Pill('Today', tone: PillTone.ember),
              const SizedBox(height: AppSpacing.md),
              Text(
                session.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                session.subtitle,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  _HeaderStat(
                      value: '${session.exercises.length}', label: 'Exercises'),
                  const SizedBox(width: AppSpacing.xl),
                  _HeaderStat(
                      value: '${session.totalTargetSets}', label: 'Sets'),
                  const SizedBox(width: AppSpacing.xl),
                  _HeaderStat(value: '~$_estMinutes', label: 'Minutes'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionLabel('Exercises'),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < session.exercises.length; i++) ...[
          _ExerciseRow(index: i + 1, exercise: session.exercises[i]),
          if (i < session.exercises.length - 1)
            Divider(color: p.line, height: 1),
        ],
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start workout'),
        ),
      ],
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.index, required this.exercise});

  final int index;
  final WorkoutExercise exercise;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ex = exercise.exercise;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
            child: Text('$index',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: p.muted, fontSize: 13)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ex.name, style: context.textStyles.titleMedium),
                Text('${ex.muscleGroup} · ${ex.equipment}',
                    style: context.textStyles.bodySmall
                        ?.copyWith(color: p.muted)),
              ],
            ),
          ),
          Text(
            '${ex.targetSets} × ${ex.targetReps}',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: p.text,
                fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}
