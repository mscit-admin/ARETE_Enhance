import 'dart:convert';

import 'package:arete/core/constants/enums.dart';
import 'package:arete/data/models/nutrition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MealPlan round-trips through JSON (the API contract)', () {
    const food = FoodItem(
      id: 'f1',
      name: 'Oats',
      serving: '1 cup',
      kcal: 300,
      proteinG: 10,
      carbsG: 50,
      fatG: 5,
    );
    const meal = PlannedMeal(
      id: 'm1',
      type: MealType.breakfast,
      title: 'Breakfast',
      items: [food],
      note: 'eat early',
    );
    const day = DayMealPlan(weekday: 2, meals: [meal]);
    const plan =
        MealPlan(id: 'plan_x', title: 'Cut', coachName: 'Coach', days: [day]);

    // Simulate the wire: encode -> decode -> parse.
    final restored = MealPlan.fromJson(
        jsonDecode(jsonEncode(plan.toJson())) as Map<String, dynamic>);

    expect(restored.title, 'Cut');
    expect(restored.coachName, 'Coach');
    expect(restored.days.length, 1);
    final d = restored.days.single;
    expect(d.weekday, 2);
    final m = d.meals.single;
    expect(m.type, MealType.breakfast);
    expect(m.note, 'eat early');
    expect(m.items.single.name, 'Oats');
    expect(m.kcal, 300);
  });
}
