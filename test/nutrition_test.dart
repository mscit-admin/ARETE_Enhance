import 'package:arete/core/constants/enums.dart';
import 'package:arete/data/repositories/mock_nutrition_repository.dart';
import 'package:arete/data/repositories/mock_profile_repository.dart';
import 'package:arete/state/nutrition_controller.dart';
import 'package:arete/state/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

NutritionController _makeController() =>
    NutritionController(MockNutritionRepository(),
        ProfileController(MockProfileRepository()));

void main() {
  group('NutritionController', () {
    test('loads the weekly plan and food library', () async {
      final c = _makeController();
      await c.load();
      expect(c.status, LoadStatus.ready);
      expect(c.plan, isNotNull);
      expect(c.library, isNotEmpty);
      // A plan is provided for every weekday.
      for (var wd = 1; wd <= 7; wd++) {
        expect(c.plan!.dayFor(wd), isNotNull);
      }
    });

    test('consumed calories only count meals that are ticked off', () async {
      final c = _makeController();
      await c.load();
      c.selectDay(1);
      expect(c.consumedKcal, 0);
      expect(c.eatenCount, 0);

      final firstMeal = c.selectedDay!.meals.first;
      c.toggleEaten(1, firstMeal.id);
      expect(c.isEaten(1, firstMeal.id), isTrue);
      expect(c.consumedKcal, firstMeal.kcal);
      expect(c.eatenCount, 1);

      // Un-ticking removes it again.
      c.toggleEaten(1, firstMeal.id);
      expect(c.isEaten(1, firstMeal.id), isFalse);
      expect(c.consumedKcal, 0);
    });

    test('logged meals add to the day and can be removed', () async {
      final c = _makeController();
      await c.load();
      c.selectDay(2);

      final apple = c.library.firstWhere((f) => f.name == 'Apple');
      c.addFromLibrary(2, MealType.snack, apple);
      expect(c.loggedFor(2, MealType.snack), hasLength(1));
      expect(c.consumedKcal, apple.kcal);

      c.addCustom(2, MealType.dinner, 'Home soup', 150);
      expect(c.consumedKcal, apple.kcal + 150);

      final logged = c.loggedFor(2, MealType.snack).first;
      c.removeLogged(2, logged.id);
      expect(c.loggedFor(2, MealType.snack), isEmpty);
      expect(c.consumedKcal, 150);
    });

    test('eaten state and logged meals are scoped per weekday', () async {
      final c = _makeController();
      await c.load();

      final mondayMeal = c.plan!.dayFor(1)!.meals.first;
      c.toggleEaten(1, mondayMeal.id);

      // Selecting Tuesday shows none of Monday's progress.
      c.selectDay(2);
      expect(c.eatenCount, 0);
      expect(c.consumedKcal, 0);

      // Back to Monday, the tick is still there.
      c.selectDay(1);
      expect(c.eatenCount, 1);
    });
  });
}
