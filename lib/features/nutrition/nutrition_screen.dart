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
import '../../state/nutrition_controller.dart';
import '../../state/profile_controller.dart';
import 'meal_picker_sheet.dart';

/// The order meal slots are shown in, top to bottom.
const _mealOrder = [
  MealType.breakfast,
  MealType.lunch,
  MealType.snack,
  MealType.dinner,
];

/// Localized short weekday name for 1 = Mon … 7 = Sun.
String weekdayShort(AppLocalizations l, int weekday) => switch (weekday) {
      1 => l.weekdayMon,
      2 => l.weekdayTue,
      3 => l.weekdayWed,
      4 => l.weekdayThu,
      5 => l.weekdayFri,
      6 => l.weekdaySat,
      _ => l.weekdaySun,
    };

/// Food & Drink — the member's daily nutrition screen. Shows the coach's plan
/// for the chosen day, lets them tick meals off, log extra meals, and track
/// water.
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = context.read<NutritionController>();
      if (c.status == LoadStatus.idle) c.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NutritionController>();
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.foodDrinkTitle)),
      body: SafeArea(
        child: switch (c.status) {
          LoadStatus.idle || LoadStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          LoadStatus.error => Center(child: Text(l.foodDrinkCouldNotLoad)),
          LoadStatus.ready => const _Body(),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NutritionController>();
    // Keep the water row in sync with the shared profile stats.
    context.watch<ProfileController>();
    final l = AppLocalizations.of(context);
    final plan = c.plan;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.xxxl),
      children: [
        if (plan != null) ...[
          _PlanHeader(title: plan.title, coach: plan.coachName),
          const SizedBox(height: AppSpacing.md),
        ],
        _DaySelector(
          selected: c.selectedWeekday,
          today: DateTime.now().weekday,
          onSelect: c.selectDay,
        ),
        const SizedBox(height: AppSpacing.lg),
        const _SummaryCard(),
        const SizedBox(height: AppSpacing.xl),
        for (final type in _mealOrder) ...[
          _MealSection(type: type),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (c.selectedDay == null)
          Text(l.foodDrinkNoPlanDay,
              style: context.textStyles.bodySmall
                  ?.copyWith(color: context.palette.muted)),
      ],
    );
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({required this.title, required this.coach});

  final String title;
  final String coach;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        const Icon(Icons.restaurant_menu, size: 18, color: AppColors.accent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: context.textStyles.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          l.foodDrinkPlanBy(coach),
          style: context.textStyles.bodySmall
              ?.copyWith(color: context.palette.muted),
        ),
      ],
    );
  }
}

/// Horizontal Mon–Sun day picker.
class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.selected,
    required this.today,
    required this.onSelect,
  });

  final int selected;
  final int today;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          for (var wd = 1; wd <= 7; wd++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _DayChip(
                  label: weekdayShort(l, wd),
                  selected: wd == selected,
                  isToday: wd == today,
                  onTap: () => onSelect(wd),
                  palette: p,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.isToday,
    required this.onTap,
    required this.palette,
  });

  final String label;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.accent : palette.surface;
    final fg = selected ? AppColors.onAccent : palette.text;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected ? AppColors.accent : palette.line,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday
                      ? (selected ? AppColors.onAccent : AppColors.accent)
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark hero card: calories consumed vs target, macro readout, and water.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NutritionController>();
    final l = AppLocalizations.of(context);
    final remaining = (c.targetKcal - c.consumedKcal).clamp(0, 1 << 30).toInt();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${c.consumedKcal}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ ${c.targetKcal} ${l.kcalUnit}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                l.foodDrinkKcalLeft(remaining),
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(height: 9, color: Colors.white.withValues(alpha: 0.12)),
                FractionallySizedBox(
                  widthFactor: c.kcalProgress,
                  child: Container(
                    height: 9,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accentPressed, AppColors.accent],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _Macro(label: l.macroProtein, grams: c.consumedProteinG),
              _Macro(label: l.macroCarbs, grams: c.consumedCarbsG),
              _Macro(label: l.macroFat, grams: c.consumedFatG),
              _MealsDoneBadge(done: c.eatenCount, total: c.plannedCount),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.water_drop, color: AppColors.water, size: 20),
              const SizedBox(width: 8),
              Text(
                l.kpiWater,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
              const SizedBox(width: 8),
              Text(
                '${c.waterGlasses}/${c.waterTarget}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.water,
                  side: BorderSide(color: AppColors.water.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 8),
                ),
                onPressed: () {
                  context.read<NutritionController>().logWater();
                },
                icon: const Icon(Icons.add, size: 16, color: AppColors.water),
                label: Text(l.foodDrinkAddGlass),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({required this.label, required this.grams});

  final String label;
  final int grams;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$grams g',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealsDoneBadge extends StatelessWidget {
  const _MealsDoneBadge({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$done/$total',
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          l.foodDrinkMealsDone.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

/// One meal slot: its planned meals, self-logged meals, and an add button.
class _MealSection extends StatelessWidget {
  const _MealSection({required this.type});

  final MealType type;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NutritionController>();
    final l = AppLocalizations.of(context);
    final wd = c.selectedWeekday;
    final planned = c.selectedDay?.mealsOfType(type) ?? const <PlannedMeal>[];
    final logged = c.loggedFor(wd, type);

    var sectionKcal = 0;
    for (final m in planned) {
      if (c.isEaten(wd, m.id)) sectionKcal += m.kcal;
    }
    for (final m in logged) {
      sectionKcal += m.kcal;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          type.localized(l),
          trailing: sectionKcal > 0
              ? Text(
                  '$sectionKcal ${l.kcalUnit}',
                  style: context.textStyles.bodySmall
                      ?.copyWith(color: context.palette.muted),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final m in planned)
          _PlannedMealCard(
            meal: m,
            eaten: c.isEaten(wd, m.id),
            onToggle: () => c.toggleEaten(wd, m.id),
          ),
        for (final m in logged)
          _LoggedMealCard(
            meal: m,
            onRemove: () => c.removeLogged(wd, m.id),
          ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => showMealPickerSheet(context, wd, type),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l.foodDrinkAddMeal),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
        ),
      ],
    );
  }
}

class _PlannedMealCard extends StatelessWidget {
  const _PlannedMealCard({
    required this.meal,
    required this.eaten,
    required this.onToggle,
  });

  final PlannedMeal meal;
  final bool eaten;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final items = meal.items.map((f) => f.name).join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: eaten ? AppColors.accent : p.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(meal.title,
                          style: context.textStyles.titleMedium,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text('${meal.kcal} ${l.kcalUnit}',
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(items,
                    style:
                        context.textStyles.bodySmall?.copyWith(color: p.muted)),
                if (meal.note != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 13, color: p.muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(meal.note!,
                            style: context.textStyles.bodySmall?.copyWith(
                                color: p.muted,
                                fontStyle: FontStyle.italic,
                                fontSize: 11.5)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _EatenToggle(eaten: eaten, onToggle: onToggle),
        ],
      ),
    );
  }
}

class _EatenToggle extends StatelessWidget {
  const _EatenToggle({required this.eaten, required this.onToggle});

  final bool eaten;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      label: eaten ? l.foodDrinkEaten : l.foodDrinkMarkEaten,
      button: true,
      child: InkResponse(
        onTap: onToggle,
        radius: 26,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: eaten ? AppColors.accent : Colors.transparent,
            border: Border.all(
              color: eaten ? AppColors.accent : context.palette.line,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.check,
            size: 18,
            color: eaten ? AppColors.onAccent : context.palette.muted,
          ),
        ),
      ),
    );
  }
}

class _LoggedMealCard extends StatelessWidget {
  const _LoggedMealCard({required this.meal, required this.onRemove});

  final LoggedMeal meal;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: AppColors.teal),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(meal.name,
                style: context.textStyles.titleMedium?.copyWith(fontSize: 14),
                overflow: TextOverflow.ellipsis),
          ),
          Text('${meal.kcal} ${l.kcalUnit}',
              style: context.textStyles.bodySmall?.copyWith(color: p.muted)),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: l.foodDrinkRemove,
            onPressed: onRemove,
            icon: Icon(Icons.close, size: 18, color: p.muted),
          ),
        ],
      ),
    );
  }
}
