import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/l10n/enum_labels.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/nutrition.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/section_label.dart';
import '../../state/meal_plan_builder_controller.dart';
import '../../state/profile_controller.dart';
import '../nutrition/nutrition_screen.dart' show weekdayShort;

const _slotOrder = [
  MealType.breakfast,
  MealType.lunch,
  MealType.snack,
  MealType.dinner,
];

/// Coach-side weekly meal-plan builder. The coach composes each day's meals
/// from the food library and saves the plan for their members.
class MealPlanBuilderScreen extends StatefulWidget {
  const MealPlanBuilderScreen({super.key});

  @override
  State<MealPlanBuilderScreen> createState() => _MealPlanBuilderScreenState();
}

class _MealPlanBuilderScreenState extends State<MealPlanBuilderScreen> {
  final _titleCtrl = TextEditingController();
  bool _titleInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = context.read<MealPlanBuilderController>();
      if (c.status == LoadStatus.idle) c.load();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final c = context.read<MealPlanBuilderController>();
    final ok = await c.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? l.mealBuilderSaved : l.mealBuilderSaveFailed)),
    );
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<MealPlanBuilderController>();
    final l = AppLocalizations.of(context);

    // Seed the title field once the plan has loaded.
    if (c.status == LoadStatus.ready && !_titleInit) {
      _titleCtrl.text = c.title;
      _titleInit = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.mealBuilderTitle),
        actions: [
          if (c.status == LoadStatus.ready)
            TextButton(
              onPressed: c.saving ? null : _save,
              child: c.saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.actionSave),
            ),
        ],
      ),
      body: SafeArea(
        child: switch (c.status) {
          LoadStatus.idle || LoadStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          LoadStatus.error => Center(child: Text(l.foodDrinkCouldNotLoad)),
          LoadStatus.ready => _Body(titleCtrl: _titleCtrl),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.titleCtrl});

  final TextEditingController titleCtrl;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<MealPlanBuilderController>();
    final l = AppLocalizations.of(context);
    final wd = c.selectedWeekday;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.xxxl),
      children: [
        TextField(
          controller: titleCtrl,
          textCapitalization: TextCapitalization.words,
          onChanged: c.setTitle,
          decoration: InputDecoration(
            labelText: l.mealBuilderPlanName,
            isDense: true,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _DayRow(selected: wd, onSelect: c.selectDay),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                l.mealBuilderDayTotal(c.dayKcal(wd)),
                style: context.textStyles.bodySmall
                    ?.copyWith(color: context.palette.muted),
              ),
            ),
            TextButton.icon(
              onPressed: () => _confirmCopy(context, wd),
              icon: const Icon(Icons.copy_all, size: 16),
              label: Text(l.mealBuilderCopyToAll),
              style: TextButton.styleFrom(foregroundColor: AppColors.teal),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final type in _slotOrder) ...[
          _SlotEditor(weekday: wd, type: type),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }

  Future<void> _confirmCopy(BuildContext context, int weekday) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.mealBuilderCopyToAll),
        content: Text(l.mealBuilderCopyConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.actionApply),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<MealPlanBuilderController>().copyDayToAll(weekday);
    }
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final today = DateTime.now().weekday;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          for (var wd = 1; wd <= 7; wd++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Material(
                  color: wd == selected ? AppColors.accent : p.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    onTap: () => onSelect(wd),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: wd == selected
                              ? AppColors.accent
                              : (wd == today ? AppColors.accent : p.line),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          weekdayShort(l, wd),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: wd == selected
                                ? AppColors.onAccent
                                : p.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SlotEditor extends StatelessWidget {
  const _SlotEditor({required this.weekday, required this.type});

  final int weekday;
  final MealType type;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<MealPlanBuilderController>();
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final foods = c.foodsFor(weekday, type);
    final kcal = foods.fold<int>(0, (s, f) => s + f.kcal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          type.localized(l),
          trailing: kcal > 0
              ? Text('$kcal ${l.kcalUnit}',
                  style: context.textStyles.bodySmall?.copyWith(color: p.muted))
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (foods.isEmpty)
          Text(l.mealBuilderNoFoods,
              style: context.textStyles.bodySmall?.copyWith(color: p.muted)),
        for (var i = 0; i < foods.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: p.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(foods[i].name,
                          style: context.textStyles.titleMedium
                              ?.copyWith(fontSize: 14)),
                      Text(foods[i].serving,
                          style: context.textStyles.bodySmall
                              ?.copyWith(color: p.muted)),
                    ],
                  ),
                ),
                Text('${foods[i].kcal} ${l.kcalUnit}',
                    style: context.textStyles.bodySmall
                        ?.copyWith(color: p.muted)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: l.foodDrinkRemove,
                  onPressed: () => c.removeFoodAt(weekday, type, i),
                  icon: Icon(Icons.close, size: 18, color: p.muted),
                ),
              ],
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => _pickFood(context, weekday, type),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l.mealBuilderAddFood),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFood(
      BuildContext context, int weekday, MealType type) async {
    final controller = context.read<MealPlanBuilderController>();
    final food = await showModalBottomSheet<FoodItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => _FoodLibrarySheet(library: controller.library),
    );
    if (food != null) controller.addFood(weekday, type, food);
  }
}

/// A searchable list of library foods that returns the chosen one.
class _FoodLibrarySheet extends StatefulWidget {
  const _FoodLibrarySheet({required this.library});

  final List<FoodItem> library;

  @override
  State<_FoodLibrarySheet> createState() => _FoodLibrarySheetState();
}

class _FoodLibrarySheetState extends State<_FoodLibrarySheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final results = _query.isEmpty
        ? widget.library
        : widget.library
            .where((f) => f.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md,
                  AppSpacing.lg, AppSpacing.sm),
              child: TextField(
                onChanged: (q) => setState(() => _query = q),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l.foodDrinkSearchHint,
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(l.foodDrinkNoResults,
                          style: context.textStyles.bodySmall
                              ?.copyWith(color: p.muted)),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: p.line, height: 1),
                      itemBuilder: (context, i) {
                        final f = results[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(f.name,
                              style: context.textStyles.titleMedium),
                          subtitle: Text(
                              '${f.serving} · ${f.proteinG}P ${f.carbsG}C ${f.fatG}F',
                              style: context.textStyles.bodySmall
                                  ?.copyWith(color: p.muted)),
                          trailing: Text('${f.kcal} ${l.kcalUnit}',
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                          onTap: () => Navigator.of(context).pop(f),
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
