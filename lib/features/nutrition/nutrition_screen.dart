import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/reminder_math.dart';
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

class _MealsCard extends StatelessWidget {
  const _MealsCard();

  @override
  Widget build(BuildContext context) {
    final meals = context.watch<MealScheduleController>();
    final n = context.watch<NutritionController>();
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final slots = meals.slots;
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
                        l.nutritionMealsDone(done, meals.activeSlots.length),
                        style: context.textStyles.titleMedium,
                      ),
                      Text(
                        next == null
                            ? l.nutritionNoMealsLeft
                            : l.nutritionNextMeal(
                                mealLabel(l, next),
                                formatMinuteOfDay(context, next.minuteOfDay),
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
          for (final slot in slots) ...[
            CheckboxListTile(
              value: n.isMealDone(slot.id),
              activeColor: AppColors.gold,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (_) =>
                  context.read<NutritionController>().toggleMealDone(slot.id),
              title: Text(
                mealLabel(l, slot),
                style: TextStyle(
                  decoration: n.isMealDone(slot.id)
                      ? TextDecoration.lineThrough
                      : null,
                  color: slot.enabled ? null : p.muted,
                ),
              ),
              subtitle: Text(
                slot.note.trim().isEmpty
                    ? formatMinuteOfDay(context, slot.minuteOfDay)
                    : '${formatMinuteOfDay(context, slot.minuteOfDay)} · ${slot.note.trim()}',
              ),
              secondary: IconButton(
                tooltip: l.alertsEditMeal,
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _editTime(context, slot),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Re-time a meal straight from the list; the reminder follows.
  Future<void> _editTime(BuildContext context, MealSlot slot) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: slot.hour, minute: slot.minute),
    );
    if (picked == null || !context.mounted) return;
    await context.read<MealScheduleController>().setTime(
          slot.id,
          ReminderMath.toMinuteOfDay(picked.hour, picked.minute),
        );
  }
}
