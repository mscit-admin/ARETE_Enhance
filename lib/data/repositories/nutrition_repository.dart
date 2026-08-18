import '../models/nutrition.dart';

/// Source of the member's assigned meal plan and the food library they can log
/// extra meals from.
abstract class NutritionRepository {
  Future<MealPlan> getMealPlan();
  Future<List<FoodItem>> getFoodLibrary();

  /// Persist a plan authored by the coach so the member sees it on next load.
  Future<void> saveMealPlan(MealPlan plan);
}
