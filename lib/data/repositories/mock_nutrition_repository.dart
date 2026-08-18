import '../mock/mock_nutrition.dart';
import '../models/nutrition.dart';
import 'nutrition_repository.dart';

class MockNutritionRepository implements NutritionRepository {
  static const _latency = Duration(milliseconds: 300);

  @override
  Future<MealPlan> getMealPlan() async {
    await Future.delayed(_latency);
    return MockNutrition.weeklyPlan();
  }

  @override
  Future<List<FoodItem>> getFoodLibrary() async {
    await Future.delayed(_latency);
    return MockNutrition.foodLibrary();
  }
}
