import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/meal_slot.dart';
import '../../data/models/nutrition.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pill.dart';
import '../../shared/widgets/section_label.dart';
import '../../state/coach_plan_sync.dart';
import '../../state/hydration_controller.dart';
import '../../state/meal_schedule_controller.dart';
import '../../state/nutrition_controller.dart';
import '../alerts/alerts_screen.dart';
import 'widgets/meal_editor_sheet.dart';
import 'widgets/weekday_picker.dart';

/// Meals & Drinks — today's water intake against the daily goal, and the fixed
/// meal schedule with what has already been eaten.
///
/// The goal set here is what the water reminders are spread across, and the
/// schedule here is what the meal reminders fire from.
class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.nutritionTitle),
        actions: [
          IconButton(
            tooltip: l.alertsTitle,
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AlertsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: context.read<NutritionController>().load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            const _CoachPlanCard(),
            SectionLabel(l.nutritionPlanSection),
            const SizedBox(height: AppSpacing.sm),
            const _PlanCard(),
            const SizedBox(height: AppSpacing.xl),
            SectionLabel(l.nutritionWaterSection),
            const SizedBox(height: AppSpacing.sm),
            const _WaterCard(),
            const SizedBox(height: AppSpacing.xl),
            SectionLabel(l.nutritionMealsSection),
            const SizedBox(height: AppSpacing.sm),
            const _MealsCard(),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

/// The plan the coach sent, if any: who wrote it, their note, and a way to put
/// it back in place after the member has adjusted things.
class _CoachPlanCard extends StatelessWidget {
  const _CoachPlanCard();

  @override
  Widget build(BuildContext context) {
    final n = context.watch<NutritionController>();
    final plan = n.coachPlan;
    final l = AppLocalizations.of(context);
    final p = context.palette;
    if (plan == null) return const SizedBox.shrink();

    final isNew = n.hasUnappliedCoachPlan;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        borderColor: AppColors.teal.withValues(alpha: 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_turned_in_outlined,
                    color: AppColors.teal),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    plan.coachName.isEmpty
                        ? l.nutritionCoachPlan
                        : l.nutritionCoachPlanFrom(plan.coachName),
                    style: context.textStyles.titleMedium,
                  ),
                ),
                if (isNew)
                  Pill(l.nutritionCoachPlanNew, tone: PillTone.teal),
              ],
            ),
            if (plan.note.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(plan.note.trim(), style: context.textStyles.bodySmall),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              isNew ? l.nutritionCoachPlanPending : l.nutritionCoachPlanApplied,
              style: context.textStyles.bodySmall?.copyWith(color: p.muted),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final applied = await applyCoachNutritionPlan(
                  nutrition: context.read<NutritionController>(),
                  meals: context.read<MealScheduleController>(),
                  hydration: context.read<HydrationController>(),
                );
                if (!applied) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l.nutritionCoachPlanRestored),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.restart_alt, size: 18),
              label: Text(isNew
                  ? l.nutritionCoachPlanApply
                  : l.nutritionCoachPlanRestore),
            ),
          ],
        ),
      ),
    );
  }
}

/// How long the plan runs for and how many meals a day it holds. Both re-time
/// the reminders, so they live above the water and meal cards.
class _PlanCard extends StatelessWidget {
  const _PlanCard();

  static String _durationLabel(AppLocalizations l, int days) => switch (days) {
        7 => l.nutritionPlanWeek,
        14 => l.nutritionPlanTwoWeeks,
        30 => l.nutritionPlanMonth,
        _ => l.nutritionPlanOngoing,
      };

  static String _formatDay(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final n = context.watch<NutritionController>();
    final meals = context.watch<MealScheduleController>();
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final end = n.planEnd;
    final daysLeft = n.planDaysLeft;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.nutritionPlanDuration, style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final days in NutritionSettings.planDurations)
                ChoiceChip(
                  label: Text(_durationLabel(l, days)),
                  selected: n.planDurationDays == days,
                  selectedColor: AppColors.gold.withValues(alpha: 0.20),
                  onSelected: (_) async {
                    final mealsController =
                        context.read<MealScheduleController>();
                    await context
                        .read<NutritionController>()
                        .setPlanDuration(days);
                    // The meal reminders only fire while the plan is running.
                    await mealsController.applySchedule();
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (end == null)
            Text(l.nutritionPlanNoEnd,
                style: context.textStyles.bodySmall?.copyWith(color: p.muted))
          else if (n.planExpired)
            Row(
              children: [
                Expanded(
                  child: Text(l.nutritionPlanEnded(_formatDay(end)),
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: AppColors.warning)),
                ),
                TextButton(
                  onPressed: () async {
                    final mealsController =
                        context.read<MealScheduleController>();
                    await context.read<NutritionController>().renewPlan();
                    await mealsController.applySchedule();
                  },
                  child: Text(l.nutritionPlanRenew),
                ),
              ],
            )
          else
            Text(
              l.nutritionPlanEnds(_formatDay(end), daysLeft ?? 0),
              style: context.textStyles.bodySmall?.copyWith(color: p.muted),
            ),

          const Divider(height: AppSpacing.xl * 2),

          // ---- meals per day ----
          Text(l.nutritionMealsPerDay, style: context.textStyles.titleMedium),
          Text(l.nutritionMealsPerDayHint,
              style: context.textStyles.bodySmall?.copyWith(color: p.muted)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: meals.mealsPerDay <=
                        NutritionSettings.minMealsPerDay
                    ? null
                    : () => context
                        .read<MealScheduleController>()
                        .setMealsPerDay(meals.mealsPerDay - 1),
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Center(
                  child: Text(l.nutritionMealsCount(meals.mealsPerDay),
                      style: context.textStyles.titleMedium),
                ),
              ),
              IconButton.filledTonal(
                onPressed: meals.mealsPerDay >=
                        NutritionSettings.maxMealsPerDay
                    ? null
                    : () => context
                        .read<MealScheduleController>()
                        .setMealsPerDay(meals.mealsPerDay + 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- water ----

class _WaterCard extends StatelessWidget {
  const _WaterCard();

  @override
  Widget build(BuildContext context) {
    final n = context.watch<NutritionController>();
    final l = AppLocalizations.of(context);
    final p = context.palette;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.water_drop, color: AppColors.water, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.nutritionGlassesOfTarget(
                          n.waterGlasses, n.waterTargetGlasses),
                      style: context.textStyles.headlineSmall,
                    ),
                    Text(
                      l.nutritionLitres(_litres(n.litresDrunk),
                          _litres(n.litresTarget)),
                      style:
                          context.textStyles.bodySmall?.copyWith(color: p.muted),
                    ),
                  ],
                ),
              ),
              Text(
                '${(n.waterProgress * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.water,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _GlassRow(filled: n.waterGlasses, total: n.waterTargetGlasses),
          const SizedBox(height: AppSpacing.md),
          Text(
            n.glassesLeft == 0
                ? l.nutritionGoalReached
                : l.nutritionGlassesLeft(n.glassesLeft),
            style: context.textStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppColors.water),
                  onPressed: () =>
                      context.read<NutritionController>().logGlass(),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l.nutritionAddGlass),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton(
                onPressed: n.waterGlasses == 0
                    ? null
                    : () => context.read<NutritionController>().removeGlass(),
                child: const Icon(Icons.remove, size: 18),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl * 2),

          // ---- the goal the reminders are built from ----
          Text(l.nutritionDailyTarget, style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(l.nutritionTargetHint,
              style: context.textStyles.bodySmall?.copyWith(color: p.muted)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: n.waterTargetGlasses <=
                        NutritionSettings.minTargetGlasses
                    ? null
                    : () => context
                        .read<NutritionController>()
                        .setTargetGlasses(n.waterTargetGlasses - 1),
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    l.nutritionGlassesCount(n.waterTargetGlasses),
                    style: context.textStyles.titleMedium,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: n.waterTargetGlasses >=
                        NutritionSettings.maxTargetGlasses
                    ? null
                    : () => context
                        .read<NutritionController>()
                        .setTargetGlasses(n.waterTargetGlasses + 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l.nutritionGlassSize, style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final ml in NutritionSettings.glassSizes)
                ChoiceChip(
                  label: Text(l.nutritionMl(ml)),
                  selected: n.glassMl == ml,
                  selectedColor: AppColors.water.withValues(alpha: 0.20),
                  onSelected: (_) =>
                      context.read<NutritionController>().setGlassMl(ml),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _litres(double value) => value.toStringAsFixed(2);
}

/// A row of glass icons — filled up to what has been drunk today.
class _GlassRow extends StatelessWidget {
  const _GlassRow({required this.filled, required this.total});

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Anything drunk beyond the goal still shows, so the row never lies.
    final shown = total > filled ? total : filled;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < shown; i++)
          Icon(
            i < filled ? Icons.local_drink : Icons.local_drink_outlined,
            size: 22,
            color: i < filled ? AppColors.water : p.muted,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- meals ----

class _MealsCard extends StatefulWidget {
  const _MealsCard();

  @override
  State<_MealsCard> createState() => _MealsCardState();
}

class _MealsCardState extends State<_MealsCard> {
  /// The weekday on screen. Only meaningful for a weekly plan; it starts on
  /// today so the card opens on what the member is eating now.
  int _day = DateTime.now().weekday;

  @override
  Widget build(BuildContext context) {
    final meals = context.watch<MealScheduleController>();
    final n = context.watch<NutritionController>();
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final weekly = meals.weekly;
    final isToday = !weekly || _day == DateTime.now().weekday;
    final slots = weekly ? meals.slotsFor(_day) : meals.slots;
    final done = n.doneCount(slots);
    final next = meals.nextUpcoming();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const Icon(Icons.restaurant, color: AppColors.gold, size: 24),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday
                            ? l.nutritionMealsDone(
                                done, slots.where((s) => s.enabled).length)
                            : l.nutritionMealsCount(slots.length),
                        style: context.textStyles.titleMedium,
                      ),
                      Text(
                        !isToday
                            ? l.nutritionOtherDay
                            : next == null
                                ? l.nutritionNoMealsLeft
                                : l.nutritionNextMeal(
                                    mealLabel(l, next),
                                    formatMinuteOfDay(
                                        context, next.minuteOfDay),
                                  ),
                        style: context.textStyles.bodySmall
                            ?.copyWith(color: p.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.calendar_view_week_outlined),
            title: Text(l.nutritionWeeklyPlan),
            subtitle: Text(
                weekly ? l.nutritionWeeklyPlanOn : l.nutritionWeeklyPlanOff,
                style: context.textStyles.bodySmall),
            value: weekly,
            activeColor: AppColors.gold,
            onChanged: (v) => context.read<MealScheduleController>()
                .setWeekly(v)
                .then((_) => setState(() => _day = DateTime.now().weekday)),
          ),
          if (weekly)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: WeekdayPicker(
                selected: {_day},
                onChanged: (days) =>
                    setState(() => _day = days.first),
              ),
            ),
          const Divider(height: 1),
          for (final slot in slots) ...[
            CheckboxListTile(
              value: isToday && n.isMealDone(slot.id),
              activeColor: AppColors.gold,
              controlAffinity: ListTileControlAffinity.leading,
              // Only today can be ticked off; other days are being planned.
              onChanged: !isToday
                  ? null
                  : (_) =>
                      context.read<NutritionController>().toggleMealDone(slot.id),
              title: Text(
                mealLabel(l, slot),
                style: TextStyle(
                  decoration: isToday && n.isMealDone(slot.id)
                      ? TextDecoration.lineThrough
                      : null,
                  color: slot.enabled ? null : p.muted,
                ),
              ),
              subtitle: Text(_subtitleFor(context, slot)),
              isThreeLine: slot.items.isNotEmpty,
              secondary: IconButton(
                tooltip: l.alertsEditMeal,
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _editMeal(context, slot),
              ),
            ),
            const Divider(height: 1),
          ],
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.nutritionMealsHint,
                    style:
                        context.textStyles.bodySmall?.copyWith(color: p.muted)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context
                            .read<MealScheduleController>()
                            .addSnack(days: weekly ? {_day} : const {}),
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
                if (weekly) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => _copyDay(context),
                    icon: const Icon(Icons.copy_all_outlined, size: 18),
                    label: Text(l.nutritionCopyDay),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Time on the first line, then what the meal is made of (or the note).
  static String _subtitleFor(BuildContext context, MealSlot slot) {
    final time = formatMinuteOfDay(context, slot.minuteOfDay);
    final detail = slot.items.isNotEmpty
        ? slot.itemsSummary
        : slot.note.trim();
    return detail.isEmpty ? time : '$time\n$detail';
  }

  /// Edit the meal — time, kind, name, ingredients, drinks and (on a weekly
  /// plan) which days it applies to. The reminder follows whatever changes.
  Future<void> _editMeal(BuildContext context, MealSlot slot) async {
    final meals = context.read<MealScheduleController>();
    final edited =
        await showMealEditor(context, slot: slot, weekly: meals.weekly);
    if (edited != null) await meals.upsert(edited);
  }

  /// Fill other days from the one on screen.
  Future<void> _copyDay(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final meals = context.read<MealScheduleController>();
    final days = await showCopyDaysSheet(
      context,
      from: _day,
      title: l.nutritionCopyDayTitle,
      confirmLabel: l.nutritionCopyDayConfirm,
    );
    if (days == null || days.isEmpty) return;
    await meals.copyDay(_day, days);
  }
}
