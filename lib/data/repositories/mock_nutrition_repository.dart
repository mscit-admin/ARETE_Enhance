import '../mock/mock_nutrition.dart';
import '../models/nutrition.dart';
import 'nutrition_repository.dart';

/// In-memory nutrition store for tests and offline use. A coach-assigned plan
/// (set via [assignPlan]) is what that member loads next.
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

  /// Test helper: simulate a coach assigning [plan] to [memberId].
  Future<void> assignPlan(String memberId, MealPlan plan) async {
    await Future.delayed(_latency);
    _assigned[memberId] = plan;
  }
}
