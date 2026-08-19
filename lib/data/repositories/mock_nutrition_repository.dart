import '../mock/mock_nutrition.dart';
import '../models/nutrition.dart';
import 'nutrition_repository.dart';

/// In-memory nutrition store. Meal plans are kept per member id, so a plan the
/// coach assigns to a client is what that member loads next — the same shape as
/// the workout-plan assignment flow. A single instance is shared between the
/// member's controller and the coach's builder.
class MockNutritionRepository implements NutritionRepository {
  static const _latency = Duration(milliseconds: 300);

  /// memberId → assigned plan.
  final Map<String, MealPlan> _assigned = {};

  @override
  Future<List<FoodItem>> getFoodLibrary() async {
    await Future.delayed(_latency);
    return MockNutrition.foodLibrary();
  }

  @override
  Future<MealPlan?> getAssignedPlan(String memberId) async {
    await Future.delayed(_latency);
    return _assigned[memberId];
  }

  @override
  Future<MealPlan> starterPlan() async {
    await Future.delayed(_latency);
    return MockNutrition.weeklyPlan();
  }

  @override
  Future<void> assignPlan(String memberId, MealPlan plan) async {
    await Future.delayed(_latency);
    _assigned[memberId] = plan;
  }
}
