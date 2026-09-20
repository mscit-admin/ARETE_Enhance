import '../api/api_client.dart';
import '../mock/mock_nutrition.dart';
import '../models/nutrition.dart';
import 'nutrition_repository.dart';

/// Member-side nutrition repository. The food library and blank starter plan
/// are static reference data (bundled with the app). The member's assigned
/// meal plan comes from the server (`/my-meal-plan`). Coach-side authoring and
/// assignment of templates lives in `MealPlansController`.
class ApiNutritionRepository implements NutritionRepository {
  ApiNutritionRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<FoodItem>> getFoodLibrary() async => MockNutrition.foodLibrary();

  @override
  Future<MealPlan> starterPlan() async => MockNutrition.weeklyPlan();

  @override
  Future<MealPlan?> getAssignedPlan(String memberId) async {
    try {
      final j =
          await _client.get('/api/app/my-meal-plan') as Map<String, dynamic>;
      final p = j['plan'];
      return p == null ? null : MealPlan.fromJson(p as Map<String, dynamic>);
    } catch (_) {
      // Offline or no coach — behave like "no plan assigned".
      return null;
    }
  }
}
