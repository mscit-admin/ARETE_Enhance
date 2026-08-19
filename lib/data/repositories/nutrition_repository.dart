import '../models/nutrition.dart';

/// Source of meal plans and the food library. Meal plans are assigned per
/// member by their coach — mirroring how workout plans are assigned.
abstract class NutritionRepository {
  Future<List<FoodItem>> getFoodLibrary();

  /// The plan the coach has assigned to [memberId], or null if none.
  Future<MealPlan?> getAssignedPlan(String memberId);

  /// A blank/starter plan the coach can begin authoring from.
  Future<MealPlan> starterPlan();

  /// Coach assigns (or updates) [plan] for a specific member.
  Future<void> assignPlan(String memberId, MealPlan plan);
}
