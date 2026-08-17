import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Weekday helpers shared by the meal screens.
///
/// Weekdays follow Dart's convention (`DateTime.monday` = 1). The *display*
/// order follows the member's locale, so an Arabic week starts on Saturday and
/// an English one on Sunday or Monday without any extra setting.
class Weekdays {
  const Weekdays._();

  /// The week in the order this locale writes it.
  static List<int> ordered(BuildContext context) {
    // MaterialLocalizations counts from Sunday = 0; Dart counts Monday = 1.
    final first = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    return [
      for (var i = 0; i < 7; i++) _fromSundayIndex((first + i) % 7),
    ];
  }

  static int _fromSundayIndex(int index) =>
      index == 0 ? DateTime.sunday : index;

  /// "Mon" / "الاثنين" — the localized name of a weekday.
  static String name(BuildContext context, int weekday) =>
      MaterialLocalizations.of(context).narrowWeekdays[weekday % 7];
}

/// A row of day chips. Used both to choose which day is being viewed and to
/// choose which days a meal applies to.
class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.multiSelect = false,
    this.color = AppColors.gold,
  });

  /// The selected weekdays. In single-select mode only the first is used.
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;
  final bool multiSelect;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final days = Weekdays.ordered(context);
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final day in days)
          ChoiceChip(
            label: Text(Weekdays.name(context, day)),
            selected: selected.contains(day),
            selectedColor: color.withValues(alpha: 0.20),
            visualDensity: VisualDensity.compact,
            onSelected: (isSelected) {
              if (!multiSelect) {
                onChanged({day});
                return;
              }
              final next = {...selected};
              if (isSelected) {
                next.add(day);
              } else {
                next.remove(day);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}

/// Ask which days to copy a day's meals onto. Returns the chosen days, or null
/// when dismissed.
Future<Set<int>?> showCopyDaysSheet(
  BuildContext context, {
  required int from,
  required String title,
  required String confirmLabel,
}) {
  return showModalBottomSheet<Set<int>>(
    context: context,
    builder: (sheetContext) {
      var chosen = <int>{};
      return StatefulBuilder(
        builder: (_, setState) => Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              WeekdayPicker(
                selected: chosen,
                multiSelect: true,
                onChanged: (days) =>
                    setState(() => chosen = days.where((d) => d != from).toSet()),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: chosen.isEmpty
                    ? null
                    : () => Navigator.of(sheetContext).pop(chosen),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ),
      );
    },
  );
}
