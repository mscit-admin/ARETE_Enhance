import 'package:flutter/material.dart';

import '../../../core/l10n/enum_labels.dart';
import '../../../core/notifications/reminder_math.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/meal_item.dart';
import '../../../data/models/meal_slot.dart';
import '../../../l10n/app_localizations.dart';
import 'weekday_picker.dart';

/// Edit one meal — kind, time, name, note and what it is made of.
///
/// Shared by the member (Meals & Drinks, Alerts) and the coach (plan builder),
/// so a meal is described the same way wherever it is written. Returns the
/// edited slot, or null when dismissed.
Future<MealSlot?> showMealEditor(
  BuildContext context, {
  required MealSlot slot,
  bool asCoach = false,
  bool weekly = false,
}) {
  return showModalBottomSheet<MealSlot>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        MealEditorSheet(slot: slot, asCoach: asCoach, weekly: weekly),
  );
}

class MealEditorSheet extends StatefulWidget {
  const MealEditorSheet({
    super.key,
    required this.slot,
    this.asCoach = false,
    this.weekly = false,
  });

  final MealSlot slot;

  /// A coach's edits are stamped [MealSource.coach].
  final bool asCoach;

  /// Show the weekday picker — only meaningful when the plan varies by day.
  final bool weekly;

  @override
  State<MealEditorSheet> createState() => _MealEditorSheetState();
}

class _MealEditorSheetState extends State<MealEditorSheet> {
  late MealKind _kind = widget.slot.kind;
  late int _minuteOfDay = widget.slot.minuteOfDay;
  late final List<MealItem> _items = [...widget.slot.items];
  late Set<int> _days = {...widget.slot.days};
  late final TextEditingController _name =
      TextEditingController(text: widget.slot.name);
  late final TextEditingController _note =
      TextEditingController(text: widget.slot.note);

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: ReminderMath.hourOf(_minuteOfDay),
        minute: ReminderMath.minuteOf(_minuteOfDay),
      ),
    );
    if (picked == null) return;
    setState(() =>
        _minuteOfDay = ReminderMath.toMinuteOfDay(picked.hour, picked.minute));
  }

  Future<void> _addItem([int? index]) async {
    final result = await showModalBottomSheet<MealItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ItemEditor(item: index == null ? null : _items[index]),
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        _items.add(result);
      } else {
        _items[index] = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.alertsEditMeal, style: context.textStyles.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<MealKind>(
              value: _kind,
              decoration: InputDecoration(labelText: l.alertsMealKind),
              items: [
                for (final k in MealKind.values)
                  DropdownMenuItem(value: k, child: Text(k.localized(l))),
              ],
              onChanged: (v) => v == null ? null : setState(() => _kind = v),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(TimeOfDay(
                hour: ReminderMath.hourOf(_minuteOfDay),
                minute: ReminderMath.minuteOf(_minuteOfDay),
              ).format(context)),
              trailing:
                  TextButton(onPressed: _pickTime, child: Text(l.actionChoose)),
            ),
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: l.alertsMealName),
              textInputAction: TextInputAction.next,
            ),

            // ---- which days it applies to ----
            if (widget.weekly) ...[
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.mealDaysEveryDay),
                value: _days.isEmpty,
                activeColor: AppColors.gold,
                onChanged: (everyDay) => setState(() {
                  _days = everyDay ? {} : {widget.slot.days.firstOrNull ?? DateTime.now().weekday};
                }),
              ),
              if (_days.isNotEmpty)
                WeekdayPicker(
                  selected: _days,
                  multiSelect: true,
                  onChanged: (days) => setState(() => _days = days),
                ),
            ],
            const SizedBox(height: AppSpacing.lg),

            // ---- what the meal is made of ----
            Text(l.mealItemsTitle, style: context.textStyles.titleMedium),
            Text(l.mealItemsHint,
                style: context.textStyles.bodySmall?.copyWith(color: p.muted)),
            const SizedBox(height: AppSpacing.sm),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(l.mealItemsEmpty,
                    style: context.textStyles.bodySmall),
              )
            else
              for (var i = 0; i < _items.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    _items[i].isDrink
                        ? Icons.local_cafe_outlined
                        : Icons.lunch_dining_outlined,
                    size: 20,
                    color: _items[i].isDrink ? AppColors.water : AppColors.gold,
                  ),
                  title: Text(_items[i].label),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _items.removeAt(i)),
                  ),
                  onTap: () => _addItem(i),
                ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => _addItem(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l.mealItemAdd),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _note,
              decoration: InputDecoration(labelText: l.alertsMealNote),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(
                widget.slot.copyWith(
                  kind: _kind,
                  minuteOfDay: _minuteOfDay,
                  name: _name.text.trim(),
                  note: _note.text.trim(),
                  items: _items,
                  days: _days,
                  source: widget.asCoach ? MealSource.coach : null,
                ),
              ),
              child: Text(l.alertsSave),
            ),
          ],
        ),
      ),
    );
  }
}

/// Add or edit one component of a meal.
class _ItemEditor extends StatefulWidget {
  const _ItemEditor({this.item});

  final MealItem? item;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.item?.name ?? '');
  late final TextEditingController _amount =
      TextEditingController(text: widget.item?.amount ?? '');
  late MealItemKind _kind = widget.item?.kind ?? MealItemKind.food;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.mealItemTitle, style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<MealItemKind>(
            segments: [
              ButtonSegment(
                value: MealItemKind.food,
                label: Text(l.mealItemFood),
                icon: const Icon(Icons.lunch_dining_outlined),
              ),
              ButtonSegment(
                value: MealItemKind.drink,
                label: Text(l.mealItemDrink),
                icon: const Icon(Icons.local_cafe_outlined),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: l.mealItemName),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amount,
            decoration: InputDecoration(
              labelText: l.mealItemAmount,
              hintText: l.mealItemAmountHint,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () {
              final name = _name.text.trim();
              if (name.isEmpty) {
                Navigator.of(context).pop();
                return;
              }
              Navigator.of(context).pop(MealItem(
                name: name,
                amount: _amount.text.trim(),
                kind: _kind,
              ));
            },
            child: Text(l.alertsSave),
          ),
        ],
      ),
    );
  }
}
