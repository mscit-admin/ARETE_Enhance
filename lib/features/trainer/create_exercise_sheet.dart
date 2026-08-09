import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/library_exercise.dart';
import '../../l10n/app_localizations.dart';
import '../../state/exercise_library_controller.dart';

/// Present the "new exercise" form and return the created exercise (or null).
/// [allowShare] enables the coach-only "share with my trainees" switch.
Future<LibraryExercise?> showCreateExercise(
  BuildContext context, {
  required bool allowShare,
}) {
  return showModalBottomSheet<LibraryExercise>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CreateExerciseSheet(allowShare: allowShare),
  );
}

class _CreateExerciseSheet extends StatefulWidget {
  const _CreateExerciseSheet({required this.allowShare});
  final bool allowShare;

  @override
  State<_CreateExerciseSheet> createState() => _CreateExerciseSheetState();
}

class _CreateExerciseSheetState extends State<_CreateExerciseSheet> {
  final _name = TextEditingController();
  final _nameAr = TextEditingController();
  final _muscle = TextEditingController();
  final _equipment = TextEditingController();
  String _category = 'gym';
  String _level = 'beginner';
  bool _share = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _nameAr.dispose();
    _muscle.dispose();
    _equipment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.planNameRequired)));
      return;
    }
    setState(() => _saving = true);
    final ctrl = context.read<ExerciseLibraryController>();
    final ex = await ctrl.create(
      name: _name.text.trim(),
      nameAr: _nameAr.text.trim(),
      muscleGroup: _muscle.text.trim(),
      category: _category,
      level: _level,
      equipment: _equipment.text.trim(),
      shareWithTrainees: widget.allowShare && _share,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ctrl.error ?? l.sessionSaveFailed)));
      return;
    }
    Navigator.of(context).pop(ex);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.exCreateTitle, style: context.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l.exerciseNameLabel),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _nameAr,
              decoration: InputDecoration(labelText: l.exNameAr),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _muscle,
              decoration: InputDecoration(labelText: l.exMuscle),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _Chip(
                  label: l.libGym,
                  selected: _category == 'gym',
                  onTap: () => setState(() => _category = 'gym'),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: l.libCalisthenics,
                  selected: _category == 'calisthenics',
                  onTap: () => setState(() => _category = 'calisthenics'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: _level,
              decoration: InputDecoration(labelText: l.exLevel, isDense: true),
              items: [
                DropdownMenuItem(value: 'beginner', child: Text(l.levelBeginner)),
                DropdownMenuItem(
                    value: 'intermediate', child: Text(l.levelIntermediate)),
                DropdownMenuItem(value: 'advanced', child: Text(l.levelAdvanced)),
              ],
              onChanged: (v) => setState(() => _level = v ?? 'beginner'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _equipment,
              decoration: InputDecoration(labelText: l.exEquipment),
            ),
            if (widget.allowShare) ...[
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _share,
                onChanged: (v) => setState(() => _share = v),
                title: Text(l.exShare),
                activeColor: AppColors.accent,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(l.exCreate),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.limeTintBg : p.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? AppColors.limeTintBorder : p.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.accent : p.muted,
          ),
        ),
      ),
    );
  }
}
