import '../../core/constants/enums.dart';
import '../models/nutrition.dart';

/// Seed data for the nutrition module: a searchable food library and a sample
/// weekly plan "assigned by the coach". Local-first — later this comes from the
/// backend and the coach authoring tools.
class MockNutrition {
  MockNutrition._();

  /// A small library the member can pick from when logging extra meals.
  static List<FoodItem> foodLibrary() => const [
        FoodItem(
            id: 'f_oats',
            name: 'Oatmeal with banana',
            serving: '1 bowl',
            kcal: 320,
            proteinG: 10,
            carbsG: 58,
            fatG: 6),
        FoodItem(
            id: 'f_eggs',
            name: 'Scrambled eggs (3)',
            serving: '3 eggs',
            kcal: 230,
            proteinG: 19,
            carbsG: 2,
            fatG: 16),
        FoodItem(
            id: 'f_chicken',
            name: 'Grilled chicken breast',
            serving: '150 g',
            kcal: 250,
            proteinG: 46,
            carbsG: 0,
            fatG: 6),
        FoodItem(
            id: 'f_rice',
            name: 'Brown rice',
            serving: '1 cup cooked',
            kcal: 215,
            proteinG: 5,
            carbsG: 45,
            fatG: 2),
        FoodItem(
            id: 'f_salad',
            name: 'Mixed green salad',
            serving: '1 plate',
            kcal: 120,
            proteinG: 3,
            carbsG: 12,
            fatG: 7),
        FoodItem(
            id: 'f_salmon',
            name: 'Baked salmon',
            serving: '150 g',
            kcal: 280,
            proteinG: 34,
            carbsG: 0,
            fatG: 16),
        FoodItem(
            id: 'f_yogurt',
            name: 'Greek yogurt',
            serving: '1 cup',
            kcal: 130,
            proteinG: 17,
            carbsG: 9,
            fatG: 4),
        FoodItem(
            id: 'f_almonds',
            name: 'Almonds',
            serving: '30 g',
            kcal: 175,
            proteinG: 6,
            carbsG: 6,
            fatG: 15),
        FoodItem(
            id: 'f_apple',
            name: 'Apple',
            serving: '1 medium',
            kcal: 95,
            proteinG: 0,
            carbsG: 25,
            fatG: 0),
        FoodItem(
            id: 'f_banana',
            name: 'Banana',
            serving: '1 medium',
            kcal: 105,
            proteinG: 1,
            carbsG: 27,
            fatG: 0),
        FoodItem(
            id: 'f_protein',
            name: 'Whey protein shake',
            serving: '1 scoop',
            kcal: 140,
            proteinG: 25,
            carbsG: 4,
            fatG: 2),
        FoodItem(
            id: 'f_sweetpotato',
            name: 'Sweet potato',
            serving: '1 medium',
            kcal: 180,
            proteinG: 4,
            carbsG: 41,
            fatG: 0),
      ];

  static FoodItem _byId(String id) =>
      foodLibrary().firstWhere((f) => f.id == id);

  /// A full 7-day plan. Weekdays follow [DateTime.weekday] (1 = Mon … 7 = Sun).
  static MealPlan weeklyPlan() {
    DayMealPlan day(int weekday) => DayMealPlan(
          weekday: weekday,
          meals: [
            PlannedMeal(
              id: 'm_${weekday}_b',
              type: MealType.breakfast,
              title: 'Breakfast',
              items: [_byId('f_oats'), _byId('f_eggs')],
              note: 'Eat within an hour of waking up.',
            ),
            PlannedMeal(
              id: 'm_${weekday}_l',
              type: MealType.lunch,
              title: 'Lunch',
              items: [_byId('f_chicken'), _byId('f_rice'), _byId('f_salad')],
            ),
            PlannedMeal(
              id: 'm_${weekday}_s',
              type: MealType.snack,
              title: 'Afternoon snack',
              items: [_byId('f_yogurt'), _byId('f_almonds')],
            ),
            PlannedMeal(
              id: 'm_${weekday}_d',
              type: MealType.dinner,
              title: 'Dinner',
              items: [_byId('f_salmon'), _byId('f_sweetpotato')],
              note: 'Finish eating at least 2 hours before bed.',
            ),
          ],
        );

    return MealPlan(
      id: 'plan_default',
      title: 'Lean & Strong',
      coachName: 'Coach Sami',
      days: [for (var wd = 1; wd <= 7; wd++) day(wd)],
    );
  }
}
