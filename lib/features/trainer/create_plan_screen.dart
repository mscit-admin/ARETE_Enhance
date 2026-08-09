import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/trainer_plan.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_label.dart';
import '../../state/plans_controller.dart';
import 'exercise_picker.dart';

/// A draft exercise on a specific day, backed by editable controllers.
class _ExDraft {
  _ExDraft({
    required this.day,
    this.exerciseId,
    required this.name,
    this.nameAr = '',
    this.muscleGroup = '',
  })  : weight = TextEditingController(),
        notes = TextEditingController();

  int day;
  final String? exerciseId;
  final String name;
  final String nameAr;
  final String muscleGroup;
  int sets = 3;
  int reps = 10;
  int rest = 60;
  final TextEditingController weight;
  final TextEditingController notes;

  String label(bool arabic) => (arabic && nameAr.isNotEmpty) ? nameAr : name;

  PlanExercise toModel() => PlanExercise(
        name: name,
        exerciseId: exerciseId,
        nameAr: nameAr,
        muscleGroup: muscleGroup,
        day: day,
        sets: sets,
        reps: reps,
        weight: double.tryParse(weight.text.trim().replaceAll(',', '.')),
        rest: rest,
        notes: notes.text.trim(),
      );

  void dispose() {
    weight.dispose();
    notes.dispose();
  }
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
  int _selectedDay = 0;
  final List<_ExDraft> _drafts = [];
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _addExercise() async {
    final ex = await showExercisePicker(context);
    if (ex == null || !mounted) return;
    setState(() => _drafts.add(_ExDraft(
          day: _selectedDay,
          exerciseId: ex.id,
          name: ex.name,
          nameAr: ex.nameAr,
          muscleGroup: ex.muscleGroup,
        )));
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    final exercises = [
      for (final d in _drafts)
        if (d.day < _daysPerWeek) d.toModel(),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final ar = Directionality.of(context) == TextDirection.rtl;
    final dayDrafts = _drafts.where((d) => d.day == _selectedDay).toList();

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
                    onChanged: (v) => setState(() {
                      _daysPerWeek = v;
                      if (_selectedDay >= v) _selectedDay = v - 1;
                    }),
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

            // ---- Day selector ----
            SectionLabel(l.planExercisesSection),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _daysPerWeek,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final count = _drafts.where((d) => d.day == i).length;
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
                        count > 0 ? '${l.planDay(i + 1)} · $count' : l.planDay(i + 1),
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

            if (dayDrafts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child: Text(l.planDayEmpty,
                      style: context.textStyles.bodyMedium
                          ?.copyWith(color: p.muted)),
                ),
              )
            else
              for (final d in dayDrafts) ...[
                _DraftCard(
                  draft: d,
                  arabic: ar,
                  onRemove: () => setState(() {
                    _drafts.remove(d);
                    d.dispose();
                  }),
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

            OutlinedButton.icon(
              onPressed: _addExercise,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.limeTintBorder),
                backgroundColor: AppColors.limeTintBg,
              ),
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

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.arabic,
    required this.onRemove,
    required this.onChanged,
  });
  final _ExDraft draft;
  final bool arabic;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(draft.label(arabic),
                        style: context.textStyles.titleMedium),
                    if (draft.muscleGroup.isNotEmpty)
                      Text(draft.muscleGroup,
                          style: context.textStyles.bodySmall
                              ?.copyWith(color: p.muted)),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
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
              const SizedBox(width: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.weight,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                      labelText: l.exerciseWeightLabel, isDense: true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _NumberDropdown(
                  label: l.exerciseRestLabel,
                  value: draft.rest,
                  options: const [30, 45, 60, 90, 120],
                  onChanged: (v) {
                    draft.rest = v;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: draft.notes,
            minLines: 1,
            maxLines: 2,
            decoration: InputDecoration(
                labelText: l.exerciseNotesLabel, isDense: true),
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
        for (final n in items) DropdownMenuItem(value: n, child: Text('$n')),
      ],
      onChanged: (v) => v == null ? null : onChanged(v),
    );
  }
}
