import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/trainer_plan.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../state/my_plan_controller.dart';

/// Per-exercise logging state: one weight+reps controller pair per set.
class _ExLog {
  _ExLog(this.ex) {
    final w = (ex.weight != null && ex.weight! > 0) ? _fmt(ex.weight!) : '';
    for (var i = 0; i < ex.sets; i++) {
      weights.add(TextEditingController(text: w));
      reps.add(TextEditingController(text: '${ex.reps}'));
    }
  }

  final PlanExercise ex;
  final List<TextEditingController> weights = [];
  final List<TextEditingController> reps = [];

  static String _fmt(double d) =>
      d == d.roundToDouble() ? d.toInt().toString() : d.toString();

  void dispose() {
    for (final c in weights) {
      c.dispose();
    }
    for (final c in reps) {
      c.dispose();
    }
  }
}

/// Trainee session runner: log the actual weight/reps for each set of the
/// selected plan day, then save the session to the server.
class PlanSessionScreen extends StatefulWidget {
  const PlanSessionScreen({super.key, required this.plan, required this.dayIndex});

  final TrainerPlan plan;
  final int dayIndex;

  @override
  State<PlanSessionScreen> createState() => _PlanSessionScreenState();
}

class _PlanSessionScreenState extends State<PlanSessionScreen> {
  late final List<_ExLog> _logs;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _logs = [
      for (final e in widget.plan.exercises)
        if (e.day == widget.dayIndex) _ExLog(e),
    ];
  }

  @override
  void dispose() {
    for (final x in _logs) {
      x.dispose();
    }
    super.dispose();
  }

  Future<void> _finish() async {
    final l = AppLocalizations.of(context);
    final sets = <Map<String, dynamic>>[];
    for (final log in _logs) {
      for (var i = 0; i < log.weights.length; i++) {
        final w = double.tryParse(
                log.weights[i].text.trim().replaceAll(',', '.')) ??
            0;
        final r = int.tryParse(log.reps[i].text.trim()) ?? 0;
        sets.add({
          if (log.ex.exerciseId != null) 'exerciseId': log.ex.exerciseId,
          'exerciseName': log.ex.name,
          'setNumber': i + 1,
          'weight': w,
          'reps': r,
        });
      }
    }
    setState(() => _saving = true);
    final err = await context.read<MyPlanController>().logSession(
          planId: widget.plan.id,
          dayIndex: widget.dayIndex,
          title: l.sessionTitle(widget.plan.name, widget.dayIndex + 1),
          sets: sets,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? l.sessionSavedOk)),
    );
    if (err == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ar = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(title: Text(l.planDay(widget.dayIndex + 1))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, 96),
          children: [
            for (final log in _logs) ...[
              _ExerciseLogCard(log: log, arabic: ar),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: SafeArea(
          top: false,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _finish,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check),
            label: Text(l.sessionFinish),
          ),
        ),
      ),
    );
  }
}

class _ExerciseLogCard extends StatelessWidget {
  const _ExerciseLogCard({required this.log, required this.arabic});
  final _ExLog log;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(log.ex.label(arabic), style: context.textStyles.titleMedium),
          Text(
            l.planSetsReps(log.ex.sets, log.ex.reps),
            style: context.textStyles.bodySmall?.copyWith(color: p.muted),
          ),
          if (log.ex.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(log.ex.notes,
                  style: context.textStyles.bodySmall
                      ?.copyWith(color: AppColors.accent)),
            ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < log.weights.length; i++) ...[
            Row(
              children: [
                SizedBox(
                  width: 54,
                  child: Text(l.sessionSetLabel(i + 1),
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: p.muted)),
                ),
                Expanded(
                  child: TextField(
                    controller: log.weights[i],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                        labelText: l.sessionWeight, isDense: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: log.reps[i],
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                        labelText: l.sessionReps, isDense: true),
                  ),
                ),
              ],
            ),
            if (i < log.weights.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
