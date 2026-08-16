import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/enum_labels.dart';
import '../../core/notifications/reminder_math.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/fitness_tip.dart';
import '../../data/models/meal_slot.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_label.dart';
import '../../state/hydration_controller.dart';
import '../../state/meal_schedule_controller.dart';
import '../../state/tips_controller.dart';

/// Every reminder ARETE can raise, in one place: water (driven by the daily
/// target), the meal schedule, and the daily fitness tip.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.alertsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          const _PermissionCard(),
          SectionLabel(l.alertsWaterSection),
          const SizedBox(height: AppSpacing.sm),
          const _WaterSection(),
          const SizedBox(height: AppSpacing.xl),
          SectionLabel(l.alertsMealsSection),
          const SizedBox(height: AppSpacing.sm),
          const _MealsSection(),
          const SizedBox(height: AppSpacing.xl),
          SectionLabel(l.alertsTipsSection),
          const SizedBox(height: AppSpacing.sm),
          const _TipsSection(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

/// Shown until the member allows Android to post notifications — without it
/// nothing on this screen can fire.
class _PermissionCard extends StatelessWidget {
  const _PermissionCard();

  @override
  Widget build(BuildContext context) {
    final hydration = context.watch<HydrationController>();
    final l = AppLocalizations.of(context);
    if (hydration.permissionGranted) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        borderColor: AppColors.warning.withValues(alpha: 0.5),
        child: Row(
          children: [
            const Icon(Icons.notifications_off_outlined,
                color: AppColors.warning),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.hydrationSystemNotifs,
                      style: context.textStyles.titleMedium),
                  Text(l.hydrationNotAllowed,
                      style: context.textStyles.bodySmall),
                ],
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.read<HydrationController>().requestPermission(),
              child: Text(l.hydrationEnable),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- water ----

class _WaterSection extends StatelessWidget {
  const _WaterSection();

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HydrationController>();
    final l = AppLocalizations.of(context);
    final p = context.palette;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.water_drop_outlined,
                color: AppColors.water),
            title: Text(l.hydrationRemindTitle),
            subtitle: Text(
              !h.enabled
                  ? l.alertsOff
                  : h.deriveFromTarget
                      ? l.alertsFromTargetOn(
                          h.targetGlasses,
                          formatDuration(l, h.derivedGapMinutes),
                        )
                      : l.hydrationCadence(
                          h.intervalHours,
                          formatHour(context, h.startHour),
                          formatHour(context, h.endHour),
                        ),
            ),
            value: h.enabled,
            activeColor: AppColors.water,
            onChanged: (v) => context.read<HydrationController>().setEnabled(v),
          ),
          if (h.enabled) ...[
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(Icons.flag_outlined),
              title: Text(l.alertsFromTarget),
              subtitle: Text(l.alertsFromTargetHint,
                  style: context.textStyles.bodySmall),
              value: h.deriveFromTarget,
              activeColor: AppColors.water,
              onChanged: (v) =>
                  context.read<HydrationController>().setDeriveFromTarget(v),
            ),
            if (!h.deriveFromTarget) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.timelapse),
                title: Text(l.hydrationEvery),
                trailing: DropdownButton<int>(
                  value: h.intervalHours,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: 1, child: Text(l.hydrationHour)),
                    DropdownMenuItem(value: 2, child: Text(l.hydrationHours(2))),
                    DropdownMenuItem(value: 3, child: Text(l.hydrationHours(3))),
                  ],
                  onChanged: (v) => v == null
                      ? null
                      : context.read<HydrationController>().setIntervalHours(v),
                ),
              ),
            ],
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(l.hydrationActiveWindow),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HourDropdown(
                    value: h.startHour,
                    options: const [5, 6, 7, 8, 9, 10],
                    onChanged: (v) => context
                        .read<HydrationController>()
                        .setWindow(startHour: v),
                  ),
                  Text('  –  ', style: TextStyle(color: p.muted)),
                  _HourDropdown(
                    value: h.endHour,
                    options: const [17, 18, 19, 20, 21, 22, 23],
                    onChanged: (v) => context
                        .read<HydrationController>()
                        .setWindow(endHour: v),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.alertsSchedulePreview,
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: p.muted)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final slot in h.slotMinutes)
                        _TimeChip(
                          label: formatMinuteOfDay(context, slot),
                          color: AppColors.water,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context
                            .read<HydrationController>()
                            .sendTestNotification();
                        _toast(context, l.hydrationTestSent);
                      },
                      icon: const Icon(Icons.notifications, size: 18),
                      label: Text(l.hydrationTest),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context
                            .read<HydrationController>()
                            .triggerInAppPromptNow();
                        Navigator.of(context).maybePop();
                      },
                      icon: const Icon(Icons.touch_app, size: 18),
                      label: Text(l.hydrationInApp),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- meals ----

class _MealsSection extends StatelessWidget {
  const _MealsSection();

  @override
  Widget build(BuildContext context) {
    final meals = context.watch<MealScheduleController>();
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final next = meals.nextUpcoming();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.restaurant_outlined,
                color: AppColors.gold),
            title: Text(l.alertsMealsSection),
            subtitle: Text(
              !meals.enabled
                  ? l.alertsOff
                  : next != null
                      ? l.alertsMealsOn(
                          meals.activeSlots.length,
                          mealLabel(l, next),
                          formatMinuteOfDay(context, next.minuteOfDay),
                        )
                      : l.alertsMealsCount(meals.activeSlots.length),
            ),
            value: meals.enabled,
            activeColor: AppColors.gold,
            onChanged: (v) =>
                context.read<MealScheduleController>().setEnabled(v),
          ),
          const Divider(height: 1),
          for (final slot in meals.slots) ...[
            ListTile(
              leading: Icon(_iconFor(slot.kind),
                  color: slot.enabled ? AppColors.gold : p.muted),
              title: Text(mealLabel(l, slot)),
              subtitle: Text(
                slot.note.trim().isEmpty
                    ? formatMinuteOfDay(context, slot.minuteOfDay)
                    : '${formatMinuteOfDay(context, slot.minuteOfDay)} · ${slot.note.trim()}',
              ),
              trailing: Switch(
                value: slot.enabled,
                activeColor: AppColors.gold,
                onChanged: (v) => context
                    .read<MealScheduleController>()
                    .setSlotEnabled(slot.id, v),
              ),
              onTap: () => _editMeal(context, slot),
            ),
            const Divider(height: 1),
          ],
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.alertsMealsHint,
                    style: context.textStyles.bodySmall
                        ?.copyWith(color: p.muted)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.read<MealScheduleController>().addSnack(),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l.alertsAddSnack),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context
                            .read<MealScheduleController>()
                            .resetToDefaults(),
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: Text(l.alertsResetSchedule),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<MealScheduleController>().sendTestNotification();
                    _toast(context, l.hydrationTestSent);
                  },
                  icon: const Icon(Icons.notifications, size: 18),
                  label: Text(l.hydrationTest),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(MealKind kind) => switch (kind) {
        MealKind.breakfast => Icons.free_breakfast_outlined,
        MealKind.snack => Icons.cookie_outlined,
        MealKind.lunch => Icons.lunch_dining_outlined,
        MealKind.dinner => Icons.dinner_dining_outlined,
        MealKind.preWorkout => Icons.bolt_outlined,
        MealKind.postWorkout => Icons.fitness_center_outlined,
      };

  Future<void> _editMeal(BuildContext context, MealSlot slot) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MealEditorSheet(slot: slot),
    );
  }
}

/// Edit one meal: kind, time, optional name and note — or remove it.
class _MealEditorSheet extends StatefulWidget {
  const _MealEditorSheet({required this.slot});

  final MealSlot slot;

  @override
  State<_MealEditorSheet> createState() => _MealEditorSheetState();
}

class _MealEditorSheetState extends State<_MealEditorSheet> {
  late MealKind _kind = widget.slot.kind;
  late int _minuteOfDay = widget.slot.minuteOfDay;
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
            title: Text(formatMinuteOfDay(context, _minuteOfDay)),
            trailing: TextButton(
              onPressed: _pickTime,
              child: Text(l.actionChoose),
            ),
          ),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l.alertsMealName),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l.alertsMealNote),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<MealScheduleController>().upsert(
                          widget.slot.copyWith(
                            kind: _kind,
                            minuteOfDay: _minuteOfDay,
                            name: _name.text.trim(),
                            note: _note.text.trim(),
                          ),
                        );
                    Navigator.of(context).pop();
                  },
                  child: Text(l.alertsSave),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: () {
                  context
                      .read<MealScheduleController>()
                      .removeSlot(widget.slot.id);
                  Navigator.of(context).pop();
                },
                child: Text(l.alertsRemove,
                    style: const TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- tips ----

class _TipsSection extends StatelessWidget {
  const _TipsSection();

  @override
  Widget build(BuildContext context) {
    final tips = context.watch<TipsController>();
    final l = AppLocalizations.of(context);
    final p = context.palette;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile(
            secondary:
                const Icon(Icons.lightbulb_outline, color: AppColors.accent),
            title: Text(l.alertsTipsSection),
            subtitle: Text(
              tips.enabled
                  ? l.alertsTipsOn(formatMinuteOfDay(context, tips.minuteOfDay))
                  : l.alertsOff,
            ),
            value: tips.enabled,
            activeColor: AppColors.accent,
            onChanged: (v) => context.read<TipsController>().setEnabled(v),
          ),
          if (tips.enabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(l.alertsTipTime),
              trailing: TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        TimeOfDay(hour: tips.hour, minute: tips.minute),
                  );
                  if (picked == null || !context.mounted) return;
                  context.read<TipsController>().setTime(
                        ReminderMath.toMinuteOfDay(picked.hour, picked.minute),
                      );
                },
                child: Text(formatMinuteOfDay(context, tips.minuteOfDay)),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.alertsTipTopics,
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: p.muted)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final category in TipCategory.values)
                        FilterChip(
                          label: Text(category.localized(l)),
                          selected: !tips.isMuted(category),
                          selectedColor:
                              AppColors.accent.withValues(alpha: 0.18),
                          onSelected: (selected) => context
                              .read<TipsController>()
                              .setCategoryMuted(category, !selected),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.tipOfDayTitle,
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: p.muted)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(tips.tipOfDayText, style: context.textStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<TipsController>().sendTestNotification();
                      _toast(context, l.hydrationTestSent);
                    },
                    icon: const Icon(Icons.notifications, size: 18),
                    label: Text(l.hydrationTest),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- shared ----

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: context.textStyles.bodySmall),
    );
  }
}

class _HourDropdown extends StatelessWidget {
  const _HourDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    // Guarantee the current value is selectable even if outside the presets.
    final items = {...options, value}.toList()..sort();
    return DropdownButton<int>(
      value: value,
      underline: const SizedBox.shrink(),
      items: [
        for (final h in items)
          DropdownMenuItem(value: h, child: Text(formatHour(context, h))),
      ],
      onChanged: (v) => v == null ? null : onChanged(v),
    );
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
  );
}

/// A minute-of-day rendered in the member's locale and clock preference.
String formatMinuteOfDay(BuildContext context, int minuteOfDay) =>
    TimeOfDay(
      hour: ReminderMath.hourOf(minuteOfDay),
      minute: ReminderMath.minuteOf(minuteOfDay),
    ).format(context);

String formatHour(BuildContext context, int hour) =>
    TimeOfDay(hour: hour, minute: 0).format(context);

/// "1 h 30 min" / "٩٠ دقيقة" — used for the derived water cadence.
String formatDuration(AppLocalizations l, int minutes) {
  if (minutes <= 0) return '';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return l.alertsDurMinutes(m);
  if (m == 0) return l.alertsDurHours(h);
  return l.alertsDurHoursMinutes(h, m);
}

/// The name to show for a meal slot: the custom name when set, else the
/// localized name of its kind.
String mealLabel(AppLocalizations l, MealSlot slot) =>
    slot.name.trim().isNotEmpty ? slot.name.trim() : slot.kind.localized(l);
