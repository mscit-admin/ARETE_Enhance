import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_controller.dart';
import '../../state/exercise_library_controller.dart';
import '../trainer/create_exercise_sheet.dart';

/// A standalone, browsable exercise library: search, filter by category,
/// create your own exercises, and delete the ones you created.
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
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
    context
        .read<ExerciseLibraryController>()
        .load(category: _category, query: _search.text.trim());
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _reload);
  }

  Future<void> _create() async {
    final isTrainer = context.read<AuthController>().user?.isTrainer ?? false;
    await showCreateExercise(context, allowShare: isTrainer);
    // The controller inserts the new exercise; refresh to reflect filters.
    _reload();
  }

  Future<void> _delete(String id) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        content: Text(l.libDeleteConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text(l.actionCancel)),
          TextButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text(l.libDelete,
                  style: const TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<ExerciseLibraryController>().deleteExercise(id);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final ctrl = context.watch<ExerciseLibraryController>();
    final ar = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(title: Text(l.libTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        icon: const Icon(Icons.add, color: AppColors.onAccent),
        label: Text(l.libCreateNew,
            style: const TextStyle(color: AppColors.onAccent)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Expanded(
                child: ctrl.loading && ctrl.items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ctrl.items.isEmpty
                        ? Center(
                            child: Text(l.libEmpty,
                                style: context.textStyles.bodyMedium
                                    ?.copyWith(color: p.muted)))
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 96),
                            itemCount: ctrl.items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (_, i) {
                              final e = ctrl.items[i];
                              return ListTile(
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
                                  [e.muscleGroup, e.level, e.equipment]
                                      .where((s) => s.isNotEmpty)
                                      .join(' · '),
                                  style: context.textStyles.bodySmall
                                      ?.copyWith(color: p.muted),
                                ),
                                trailing: e.createdByMe
                                    ? IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: AppColors.danger),
                                        onPressed: () => _delete(e.id),
                                      )
                                    : null,
                              );
                            },
                          ),
              ),
            ],
          ),
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
          border:
              Border.all(color: selected ? AppColors.limeTintBorder : p.line),
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
