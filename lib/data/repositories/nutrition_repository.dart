import '../models/nutrition.dart';

/// Member-side source of the food library and the meal plan the coach assigned.
/// Coach-side authoring/assignment of named meal-plan templates lives in
/// `MealPlansController` (backed by the API), mirroring workout plans.
abstract class NutritionRepository {
  Future<List<FoodItem>> getFoodLibrary();

  /// The member's currently assigned meal plan, or null if none.
  /// [memberId] is the current member (self); the server scopes by token.
  Future<MealPlan?> getAssignedPlan(String memberId);

  /// A blank/starter plan a coach can begin authoring a template from.
  Future<MealPlan> starterPlan();
}
