import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/enum_labels.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/meal_slot.dart';
import '../../data/models/nutrition.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_label.dart';
import '../../state/coach_nutrition_controller.dart';
import '../alerts/alerts_screen.dart' show formatMinuteOfDay;
import '../nutrition/widgets/meal_editor_sheet.dart';
import '../nutrition/widgets/weekday_picker.dart';

/// Coach side: build the meal schedule and water goal for one trainee and send
/// it. The trainee's app applies it to their own schedule, which re-times both
/// their meal and water reminders.
class CoachNutritionPlanScreen extends StatefulWidget {
  const CoachNutritionPlanScreen({
    super.key,
    required this.memberId,
    required this.memberName,
  });

  final String memberId;
  final String memberName;

  @override
  State<CoachNutritionPlanScreen> createState() =>
      _CoachNutritionPlanScreenState();
}

class _CoachNutritionPlanScreenState extends State<CoachNutritionPlanScreen> {
  final _note = TextEditingController();
  List<MealSlot> _slots = [];
  int _waterTarget = NutritionSettings.defaultTargetGlasses;
  int _durationDays = 7;
  bool _weekly = false;
  int _day = DateTime.now().weekday;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = context.read<CoachNutritionController>();
    await c.load(widget.memberId);
    if (!mounted) return;
    setState(() {
      _slots = c.startingSchedule()..sort(_byTime);
      // A plan whose meals name their days is a weekly one.
      _weekly = _slots.any((s) => !s.everyDay);
      _waterTarget = c.startingWaterTarget();
      _durationDays = c.plan?.durationDays ?? 7;
      _note.text = c.plan?.note ?? '';
      _ready = true;
    });
  }

  static int _byTime(MealSlot a, MealSlot b) =>
      a.minuteOfDay.compareTo(b.minuteOfDay);

  /// The meals shown: the whole plan, or one weekday of it.
  List<MealSlot> get _visibleSlots =>
      _weekly ? [for (final s in _slots) if (s.appliesOn(_day)) s] : _slots;

  void _upsert(MealSlot slot) {
    setState(() {
      final i = _slots.indexWhere((s) => s.id == slot.id);
      if (i >= 0) {
        _slots[i] = slot;
      } else {
        _slots.add(slot);
      }
      _slots.sort(_byTime);
    });
  }

  /// Edit an existing meal, or add the one passed in — [_upsert] covers both.
  Future<void> _editSlot(MealSlot slot) async {
    final result = await showMealEditor(context, slot: slot,
        asCoach: true, weekly: _weekly);
    if (result == null) return;
    _upsert(result);
  }

  /// Copy the day on screen onto other days, so a week is built from one.
  Future<void> _copyDay() async {
    final l = AppLocalizations.of(context);
    final days = await showCopyDaysSheet(
      context,
      from: _day,
      title: l.nutritionCopyDayTitle,
      confirmLabel: l.nutritionCopyDayConfirm,
    );
    if (days == null || days.isEmpty) return;
    final source = _slots.where((s) => s.appliesOn(_day)).toList();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      // Clear the target days out of the existing meals, then lay the source
      // day over them.
      final kept = <MealSlot>[];
      for (final slot in _slots) {
        final effective =
            slot.everyDay ? MealSlot.allWeekdays.toSet() : slot.days;
        final remaining = effective.where((d) => !days.contains(d)).toSet();
        if (remaining.isNotEmpty) kept.add(slot.copyWith(days: remaining));
      }
      for (var i = 0; i < source.length; i++) {
        kept.add(source[i].withId('coach_${stamp}_$i').copyWith(days: days));
      }
      _slots = kept..sort(_byTime);
    });
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final error = await context.read<CoachNutritionController>().send(
          mealSchedule: _slots,
          waterTargetGlasses: _waterTarget,
          durationDays: _durationDays,
          note: _note.text.trim(),
        );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? l.coachNutritionSent)),
    );
    if (error == null) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CoachNutritionController>();
    final l = AppLocalizations.of(context);
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: Text(l.coachNutritionTitle(widget.memberName))),
      body: !_ready || c.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                if (c.error != null) ...[
                  AppCard(
                    borderColor: AppColors.danger.withValues(alpha: 0.5),
                    child: Text(c.error!, style: context.textStyles.bodySmall),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (c.plan != null) ...[
                  Text(
                    l.coachNutritionLastSent(_formatDate(c.plan!.createdAt)),
                    style:
                        context.textStyles.bodySmall?.copyWith(color: p.muted),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ---- water goal ----
                SectionLabel(l.nutritionDailyTarget),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.water_drop, color: AppColors.water),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(l.nutritionGlassesCount(_waterTarget),
                            style: context.textStyles.titleMedium),
                      ),
                      IconButton.filledTonal(
                        onPressed: _waterTarget <=
                                NutritionSettings.minTargetGlasses
                            ? null
                            : () => setState(() => _waterTarget--),
                        icon: const Icon(Icons.remove),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filledTonal(
                        onPressed: _waterTarget >=
                                NutritionSettings.maxTargetGlasses
                            ? null
                            : () => setState(() => _waterTarget++),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ---- how long the plan runs ----
                SectionLabel(l.nutritionPlanDuration),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final days in NutritionSettings.planDurations)
                        ChoiceChip(
                          label: Text(_durationLabel(l, days)),
                          selected: _durationDays == days,
                          selectedColor: AppColors.gold.withValues(alpha: 0.20),
                          onSelected: (_) =>
                              setState(() => _durationDays = days),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ---- meals ----
                SectionLabel(l.coachNutritionMeals),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary:
                            const Icon(Icons.calendar_view_week_outlined),
                        title: Text(l.nutritionWeeklyPlan),
                        subtitle: Text(
                          _weekly
                              ? l.nutritionWeeklyPlanOn
                              : l.nutritionWeeklyPlanOff,
                          style: context.textStyles.bodySmall,
                        ),
                        value: _weekly,
                        activeColor: AppColors.gold,
                        onChanged: (v) => setState(() {
                          _weekly = v;
                          if (!v) {
                            // Back to one repeated day: every meal applies daily.
                            _slots = [
                              for (final s in _slots) s.copyWith(days: const {}),
                            ];
                          }
                        }),
                      ),
                      if (_weekly)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0,
                              AppSpacing.md, AppSpacing.md),
                          child: WeekdayPicker(
                            selected: {_day},
                            onChanged: (days) =>
                                setState(() => _day = days.first),
                          ),
                        ),
                      const Divider(height: 1),
                      for (final slot in _visibleSlots) ...[
                        ListTile(
                          leading: const Icon(Icons.restaurant_outlined,
                              color: AppColors.gold),
                          title: Text(slot.name.trim().isNotEmpty
                              ? slot.name.trim()
                              : slot.kind.localized(l)),
                          subtitle: Text(_subtitleFor(context, slot)),
                          isThreeLine: slot.items.isNotEmpty,
                          trailing: IconButton(
                            tooltip: l.alertsRemove,
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.danger),
                            onPressed: () => setState(
                                () => _slots.removeWhere((s) => s.id == slot.id)),
                          ),
                          onTap: () => _editSlot(slot),
                        ),
                        const Divider(height: 1),
                      ],
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _editSlot(
                                MealSlot(
                                  id: 'coach_${DateTime.now().millisecondsSinceEpoch}',
                                  kind: MealKind.snack,
                                  minuteOfDay: 16 * 60,
                                  source: MealSource.coach,
                                  days: _weekly ? {_day} : const {},
                                ),
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(l.coachNutritionAddMeal),
                            ),
                            if (_weekly) ...[
                              const SizedBox(height: AppSpacing.sm),
                              OutlinedButton.icon(
                                onPressed: _copyDay,
                                icon: const Icon(Icons.copy_all_outlined,
                                    size: 18),
                                label: Text(l.nutritionCopyDay),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ---- note ----
                SectionLabel(l.coachNutritionNote),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _note,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: l.coachNutritionNoteHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: c.sending || _slots.isEmpty ? null : _send,
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(c.sending
                      ? l.coachNutritionSending
                      : l.coachNutritionSend),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l.coachNutritionHint,
                    style:
                        context.textStyles.bodySmall?.copyWith(color: p.muted)),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
    );
  }

  static String _durationLabel(AppLocalizations l, int days) => switch (days) {
        7 => l.nutritionPlanWeek,
        14 => l.nutritionPlanTwoWeeks,
        30 => l.nutritionPlanMonth,
        _ => l.nutritionPlanOngoing,
      };

  /// Time, then the ingredients (or the note) of the meal.
  static String _subtitleFor(BuildContext context, MealSlot slot) {
    final time = formatMinuteOfDay(context, slot.minuteOfDay);
    final detail =
        slot.items.isNotEmpty ? slot.itemsSummary : slot.note.trim();
    return detail.isEmpty ? time : '$time\n$detail';
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '—';
    final local = d.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
