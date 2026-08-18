import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/l10n/enum_labels.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/nutrition.dart';
import '../../l10n/app_localizations.dart';
import '../../state/nutrition_controller.dart';

/// Opens the "add a meal" sheet for a given day + slot. The member can pick
/// from the food library or type a custom entry.
Future<void> showMealPickerSheet(
    BuildContext context, int weekday, MealType type) {
  final controller = context.read<NutritionController>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
    ),
    builder: (_) => ChangeNotifierProvider.value(
      value: controller,
      child: _MealPickerSheet(weekday: weekday, type: type),
    ),
  );
}

class _MealPickerSheet extends StatefulWidget {
  const _MealPickerSheet({required this.weekday, required this.type});

  final int weekday;
  final MealType type;

  @override
  State<_MealPickerSheet> createState() => _MealPickerSheetState();
}

class _MealPickerSheetState extends State<_MealPickerSheet> {
  bool _custom = false;
  String _query = '';
  final _nameCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _kcalCtrl.dispose();
    super.dispose();
  }

  void _addFood(FoodItem food) {
    context.read<NutritionController>().addFromLibrary(
          widget.weekday,
          widget.type,
          food,
        );
    _dismissWith(food.name);
  }

  void _addCustom() {
    final name = _nameCtrl.text.trim();
    final kcal = int.tryParse(_kcalCtrl.text.trim()) ?? 0;
    if (name.isEmpty) return;
    context.read<NutritionController>().addCustom(
          widget.weekday,
          widget.type,
          name,
          kcal,
        );
    _dismissWith(name);
  }

  /// Close the sheet and confirm — capturing the messenger and message up front
  /// so we never touch a deactivated context after the pop.
  void _dismissWith(String name) {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).foodDrinkMealAdded(name);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final library = context.read<NutritionController>().library;
    final results = _query.isEmpty
        ? library
        : library
            .where((f) => f.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.foodDrinkAddToMeal(widget.type.localized(l)),
                      style: context.textStyles.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: p.muted),
                  ),
                ],
              ),
            ),
            // Library / Custom toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  _ModeTab(
                    label: l.foodDrinkLibraryTab,
                    selected: !_custom,
                    onTap: () => setState(() => _custom = false),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _ModeTab(
                    label: l.foodDrinkCustomTab,
                    selected: _custom,
                    onTap: () => setState(() => _custom = true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _custom
                  ? _CustomForm(
                      nameCtrl: _nameCtrl,
                      kcalCtrl: _kcalCtrl,
                      onAdd: _addCustom,
                      scrollController: scrollController,
                    )
                  : _LibraryList(
                      results: results,
                      scrollController: scrollController,
                      onQuery: (q) => setState(() => _query = q),
                      onPick: _addFood,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
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
    return Expanded(
      child: Material(
        color: selected ? AppColors.limeTintBg : p.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: selected ? AppColors.accent : p.line,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.accent : p.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryList extends StatelessWidget {
  const _LibraryList({
    required this.results,
    required this.scrollController,
    required this.onQuery,
    required this.onPick,
  });

  final List<FoodItem> results;
  final ScrollController scrollController;
  final ValueChanged<String> onQuery;
  final ValueChanged<FoodItem> onPick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: TextField(
            onChanged: onQuery,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l.foodDrinkSearchHint,
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
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
                  separatorBuilder: (_, __) => Divider(color: p.line, height: 1),
                  itemBuilder: (context, i) {
                    final f = results[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(f.name, style: context.textStyles.titleMedium),
                      subtitle: Text('${f.serving} · ${f.proteinG}P ${f.carbsG}C ${f.fatG}F',
                          style: context.textStyles.bodySmall
                              ?.copyWith(color: p.muted)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${f.kcal} ${l.kcalUnit}',
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                          const SizedBox(width: 6),
                          const Icon(Icons.add_circle,
                              color: AppColors.accent),
                        ],
                      ),
                      onTap: () => onPick(f),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CustomForm extends StatelessWidget {
  const _CustomForm({
    required this.nameCtrl,
    required this.kcalCtrl,
    required this.onAdd,
    required this.scrollController,
  });

  final TextEditingController nameCtrl;
  final TextEditingController kcalCtrl;
  final VoidCallback onAdd;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      children: [
        TextField(
          controller: nameCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l.foodDrinkFoodName,
            isDense: true,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: kcalCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l.foodDrinkCaloriesLabel,
            isDense: true,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: Text(l.foodDrinkAddMeal),
        ),
      ],
    );
  }
}
