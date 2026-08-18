import '../mock/mock_nutrition.dart';
import '../models/nutrition.dart';
import 'nutrition_repository.dart';

/// In-memory nutrition store. A single instance is shared between the member's
/// [NutritionController] and the coach's plan builder, so a plan the coach
/// saves is what the member loads next.
class MockNutritionRepository implements NutritionRepository {
  static const _latency = Duration(milliseconds: 300);

  MealPlan _plan = MockNutrition.weeklyPlan();

  @override
  Future<MealPlan> getMealPlan() async {
    await Future.delayed(_latency);
    return _plan;
  }

  @override
  Future<List<FoodItem>> getFoodLibrary() async {
    await Future.delayed(_latency);
    return MockNutrition.foodLibrary();
  }

  @override
  Future<void> saveMealPlan(MealPlan plan) async {
    await Future.delayed(_latency);
    _plan = plan;
  }
}
