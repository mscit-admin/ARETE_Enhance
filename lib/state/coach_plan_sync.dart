import '../data/models/nutrition.dart';
import 'hydration_controller.dart';
import 'meal_schedule_controller.dart';
import 'nutrition_controller.dart';

/// Push a coach's nutrition plan onto the member's own schedule.
///
/// This is the seam between the three controllers that each own one piece:
/// the schedule (meals), the water goal (nutrition) and the reminder times
/// (hydration). Called on load when a new plan arrives, and from the Meals &
/// Drinks screen when the member asks for the coach's plan back after editing.
///
/// Returns false when there was nothing to apply.
Future<bool> applyCoachNutritionPlan({
  required NutritionController nutrition,
  required MealScheduleController meals,
  HydrationController? hydration,
  CoachNutritionPlan? plan,
}) async {
  final active = plan ?? nutrition.coachPlan;
  if (active == null || active.mealSchedule.isEmpty) return false;

  // The coach also says how long the plan should run. Start the period *before*
  // the schedule is written, so the reminder rebuild that follows already sees
  // a running plan (a previous plan may have lapsed and paused them).
  if (active.durationDays > 0) {
    await nutrition.setPlanDuration(active.durationDays);
  }
  await meals.replaceAll(active.mealSchedule);
  if (active.waterTargetGlasses != null) {
    await nutrition.setTargetGlasses(active.waterTargetGlasses!);
  }
  await nutrition.markCoachPlanApplied(active.id);
  // The water reminders are spread across the goal, so re-time them even when
  // the goal itself did not move (the schedule may have).
  await hydration?.applySchedule();
  return true;
}

/// Apply the coach's plan only if it has not been applied yet — what runs on
/// sign-in and on every nutrition refresh.
Future<bool> applyCoachNutritionPlanIfNew({
  required NutritionController nutrition,
  required MealScheduleController meals,
  HydrationController? hydration,
}) async {
  if (!nutrition.hasUnappliedCoachPlan) return false;
  return applyCoachNutritionPlan(
    nutrition: nutrition,
    meals: meals,
    hydration: hydration,
  );
}
