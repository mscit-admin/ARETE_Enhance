import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/trainer_plan.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_label.dart';
import '../../state/plans_controller.dart';

/// A draft exercise row backed by editable controllers.
class _ExerciseDraft {
  _ExerciseDraft()
      : name = TextEditingController(),
        sets = 3,
        reps = 10;
  final TextEditingController name;
  int sets;
  int reps;
  void dispose() => name.dispose();
}

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  int _daysPerWeek = 3;
  int _weeks = 8;
  final List<_ExerciseDraft> _exercises = [_ExerciseDraft()];
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    for (final e in _exercises) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    final exercises = [
      for (final e in _exercises)
        if (e.name.text.trim().isNotEmpty)
          PlanExercise(name: e.name.text.trim(), sets: e.sets, reps: e.reps),
    ];
    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.planNeedExercise)));
      return;
    }
    setState(() => _saving = true);
    final err = await context.read<PlansController>().createPlan(
          name: _name.text.trim(),
          description: _description.text.trim(),
          daysPerWeek: _daysPerWeek,
          weeks: _weeks,
          exercises: exercises,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.createPlanTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l.planNameLabel),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.planNameRequired : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _description,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(labelText: l.planDescLabel),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _NumberDropdown(
                    label: l.planDaysLabel,
                    value: _daysPerWeek,
                    options: const [2, 3, 4, 5, 6],
                    onChanged: (v) => setState(() => _daysPerWeek = v),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _NumberDropdown(
                    label: l.planWeeksLabel,
                    value: _weeks,
                    options: const [4, 6, 8, 12, 16],
                    onChanged: (v) => setState(() => _weeks = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionLabel(l.planExercisesSection),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < _exercises.length; i++) ...[
              _ExerciseRow(
                draft: _exercises[i],
                index: i + 1,
                canRemove: _exercises.length > 1,
                onRemove: () => setState(() {
                  _exercises.removeAt(i).dispose();
                }),
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            OutlinedButton.icon(
              onPressed: () => setState(() => _exercises.add(_ExerciseDraft())),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.planAddExercise),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(l.planSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.draft,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });
  final _ExerciseDraft draft;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                      labelText: '${l.exerciseNameLabel} $index', isDense: true),
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, color: AppColors.danger),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _NumberDropdown(
                  label: l.exerciseSetsLabel,
                  value: draft.sets,
                  options: const [1, 2, 3, 4, 5, 6],
                  onChanged: (v) {
                    draft.sets = v;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _NumberDropdown(
                  label: l.exerciseRepsLabel,
                  value: draft.reps,
                  options: const [5, 6, 8, 10, 12, 15, 20],
                  onChanged: (v) {
                    draft.reps = v;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberDropdown extends StatelessWidget {
  const _NumberDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = {...options, value}.toList()..sort();
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: [
        for (final n in items)
          DropdownMenuItem(value: n, child: Text('$n')),
      ],
      onChanged: (v) => v == null ? null : onChanged(v),
    );
  }
}
