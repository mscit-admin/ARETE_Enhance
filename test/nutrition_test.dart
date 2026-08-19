import 'package:arete/core/constants/enums.dart';
import 'package:arete/data/repositories/mock_nutrition_repository.dart';
import 'package:arete/data/repositories/mock_profile_repository.dart';
import 'package:arete/state/meal_plan_builder_controller.dart';
import 'package:arete/state/nutrition_controller.dart';
import 'package:arete/state/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProfileController> _loadedProfile() async {
  final p = ProfileController(MockProfileRepository());
  await p.load();
  return p;
}

void main() {
  group('NutritionController (member)', () {
    test('no plan is assigned until the coach assigns one', () async {
      final profile = await _loadedProfile();
      final c = NutritionController(MockNutritionRepository(), profile);
      await c.load();
      expect(c.status, LoadStatus.ready);
      expect(c.plan, isNull);
      expect(c.hasNoPlan, isTrue);
      expect(c.library, isNotEmpty);
    });

    test('member can log meals even without an assigned plan', () async {
      final profile = await _loadedProfile();
      final c = NutritionController(MockNutritionRepository(), profile);
      await c.load();
      c.selectDay(1);

      final apple = c.library.firstWhere((f) => f.name == 'Apple');
      c.addFromLibrary(1, MealType.snack, apple);
      c.addCustom(1, MealType.dinner, 'Home soup', 150);
      expect(c.consumedKcal, apple.kcal + 150);

      final logged = c.loggedFor(1, MealType.snack).first;
      c.removeLogged(1, logged.id);
      expect(c.consumedKcal, 150);
    });
  });

  group('Coach assigns → member sees the plan', () {
    test('assigned plan is loaded for that member and eaten totals work',
        () async {
      final repo = MockNutritionRepository();
      final profile = await _loadedProfile();
      final memberId = profile.member!.id;

      // Coach builds from the starter template and assigns to the member.
      final builder = MealPlanBuilderController(repo);
      await builder.init();
      await builder.selectClient(memberId, 'Trainee', 'Coach');
      final ok = await builder.assign();
      expect(ok, isTrue);

      // Member now loads their assigned plan.
      final member = NutritionController(repo, profile);
      await member.load();
      expect(member.plan, isNotNull);
      expect(member.hasNoPlan, isFalse);
      for (var wd = 1; wd <= 7; wd++) {
        expect(member.plan!.dayFor(wd), isNotNull);
      }

      member.selectDay(1);
      expect(member.consumedKcal, 0);
      final firstMeal = member.selectedDay!.meals.first;
      member.toggleEaten(1, firstMeal.id);
      expect(member.consumedKcal, firstMeal.kcal);
      expect(member.eatenCount, 1);
    });

    test('a plan assigned to another member is not visible', () async {
      final repo = MockNutritionRepository();
      final profile = await _loadedProfile();

      final builder = MealPlanBuilderController(repo);
      await builder.init();
      await builder.selectClient('someone_else', 'Other', 'Coach');
      await builder.assign();

      final member = NutritionController(repo, profile);
      await member.load();
      expect(member.plan, isNull);
      expect(member.hasNoPlan, isTrue);
    });
  });
}
