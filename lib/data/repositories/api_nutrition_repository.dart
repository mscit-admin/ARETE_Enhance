import '../api/api_client.dart';
import '../mock/mock_nutrition.dart';
import '../models/nutrition.dart';
import 'nutrition_repository.dart';

/// Backend-backed nutrition repository. The food library and the blank starter
/// plan are static reference data (bundled with the app); assigned meal plans
/// live on the server so they sync across devices — exactly like workout plans.
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
      final j = await _client.get('/api/app/meal-plans/$memberId')
          as Map<String, dynamic>;
      final p = j['plan'];
      return p == null ? null : MealPlan.fromJson(p as Map<String, dynamic>);
    } catch (_) {
      // Offline or no coach — behave like "no plan assigned".
      return null;
    }
  }

  @override
  Future<void> assignPlan(String memberId, MealPlan plan) async {
    await _client.post(
      '/api/app/trainer/meal-plans/$memberId',
      plan.toJson(),
      auth: true,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> assignedMembers() async {
    try {
      final j = await _client.get('/api/app/trainer/meal-plans')
          as Map<String, dynamic>;
      return (j['rows'] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> unassign(String memberId) async {
    await _client.delete('/api/app/trainer/meal-plans/$memberId');
  }
}
