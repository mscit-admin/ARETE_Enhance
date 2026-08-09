import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/library_exercise.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_controller.dart';
import '../../state/exercise_library_controller.dart';
import 'create_exercise_sheet.dart';

/// Present the exercise catalogue and return the chosen exercise (or null).
Future<LibraryExercise?> showExercisePicker(BuildContext context) {
  return showModalBottomSheet<LibraryExercise>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ExercisePickerSheet(),
  );
}

class _ExercisePickerSheet extends StatefulWidget {
  const _ExercisePickerSheet();

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  final _search = TextEditingController();
  String _category = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<ExerciseLibraryController>().load(
          category: _category,
          query: _search.text.trim(),
        );
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _reload);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final ctrl = context.watch<ExerciseLibraryController>();
    final ar = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.libTitle, style: context.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _search,
              onChanged: (_) => _onSearch(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.libSearch,
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _CatChip(
                  label: l.libAll,
                  selected: _category == '',
                  onTap: () => setState(() {
                    _category = '';
                    _reload();
                  }),
                ),
                const SizedBox(width: 8),
                _CatChip(
                  label: l.libGym,
                  selected: _category == 'gym',
                  onTap: () => setState(() {
                    _category = 'gym';
                    _reload();
                  }),
                ),
                const SizedBox(width: 8),
                _CatChip(
                  label: l.libCalisthenics,
                  selected: _category == 'calisthenics',
                  onTap: () => setState(() {
                    _category = 'calisthenics';
                    _reload();
                  }),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () async {
                final isTrainer =
                    context.read<AuthController>().user?.isTrainer ?? false;
                final created =
                    await showCreateExercise(context, allowShare: isTrainer);
                if (created != null && context.mounted) {
                  Navigator.of(context).pop(created);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.limeTintBorder),
                backgroundColor: AppColors.limeTintBg,
                minimumSize: const Size.fromHeight(42),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.libCreateNew),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ctrl.loading && ctrl.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ctrl.items.isEmpty
                      ? Center(
                          child: Text(l.libEmpty,
                              style: context.textStyles.bodyMedium
                                  ?.copyWith(color: p.muted)))
                      : ListView.separated(
                          itemCount: ctrl.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (_, i) {
                            final e = ctrl.items[i];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: AppColors.limeTintBg,
                                child: Icon(
                                  e.category == 'calisthenics'
                                      ? Icons.self_improvement
                                      : Icons.fitness_center,
                                  color: AppColors.accent,
                                  size: 18,
                                ),
                              ),
                              title: Text(e.label(ar)),
                              subtitle: Text(
                                [e.muscleGroup, e.level]
                                    .where((s) => s.isNotEmpty)
                                    .join(' · '),
                                style: context.textStyles.bodySmall
                                    ?.copyWith(color: p.muted),
                              ),
                              trailing: e.createdByMe
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: AppColors.danger),
                                      onPressed: () async {
                                        await context
                                            .read<ExerciseLibraryController>()
                                            .deleteExercise(e.id);
                                      },
                                    )
                                  : const Icon(Icons.add_circle_outline,
                                      color: AppColors.accent),
                              onTap: () => Navigator.of(context).pop(e),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.limeTintBg : p.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? AppColors.limeTintBorder : p.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.accent : p.muted,
          ),
        ),
      ),
    );
  }
}
