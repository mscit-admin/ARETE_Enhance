import 'dart:convert';

import 'package:arete/data/api/api_client.dart';
import 'package:arete/data/models/meal_item.dart';
import 'package:arete/data/models/meal_slot.dart';
import 'package:arete/data/models/nutrition.dart';
import 'package:arete/data/repositories/nutrition_repository.dart';
import 'package:arete/state/coach_plan_sync.dart';
import 'package:arete/state/meal_schedule_controller.dart';
import 'package:arete/state/nutrition_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

MockClient _serverReturning(Map<String, dynamic> body) =>
    MockClient((_) async => http.Response(jsonEncode(body), 200,
        headers: {'content-type': 'application/json'}));

MockClient get _serverDown =>
    MockClient((_) async => http.Response('{"error":"boom"}', 500,
        headers: {'content-type': 'application/json'}));

NutritionRepository _repo([http.Client? client]) =>
    NutritionRepository(ApiClient(httpClient: client ?? _serverDown));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel, (call) async {
      return const {
        'initialize',
        'requestNotificationsPermission',
        'areNotificationsEnabled',
      }.contains(call.method)
          ? true
          : null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel, null);
  });

  group('MealItem', () {
    test('labels a component with its amount when there is one', () {
      const withAmount =
          MealItem(name: 'Grilled chicken', amount: '150 g');
      expect(withAmount.label, 'Grilled chicken · 150 g');
      const plain = MealItem(name: 'Salad');
      expect(plain.label, 'Salad');
    });

    test('round trips, and drinks are distinguishable from food', () {
      const drink = MealItem(
          name: 'Green tea', amount: '1 cup', kind: MealItemKind.drink);
      final back = MealItem.fromJson(drink.toJson());
      expect(back.name, 'Green tea');
      expect(back.amount, '1 cup');
      expect(back.isDrink, isTrue);
      expect(MealItem.fromJson(const {'name': 'Rice'}).isDrink, isFalse);
    });

    test('a stored list drops unnamed and malformed entries', () {
      final items = MealItem.listFromJson([
        {'name': 'Oats', 'amount': '50 g'},
        {'name': '   '},
        'not a map',
        {'name': 'Water', 'kind': 'drink'},
      ]);
      expect(items, hasLength(2));
      expect(items.last.isDrink, isTrue);
      expect(MealItem.listFromJson(null), isEmpty);
    });
  });

  group('MealSlot with items', () {
    const slot = MealSlot(
      id: 'lunch',
      kind: MealKind.lunch,
      minuteOfDay: 13 * 60,
      items: [
        MealItem(name: 'Chicken', amount: '150 g'),
        MealItem(name: 'Rice', amount: '1 cup'),
        MealItem(name: 'Water', kind: MealItemKind.drink),
      ],
    );

    test('splits food from drinks and summarises both', () {
      expect(slot.foods, hasLength(2));
      expect(slot.drinks, hasLength(1));
      expect(slot.itemsSummary, contains('Chicken · 150 g'));
      expect(slot.itemsSummary, contains('Water'));
    });

    test('items survive the JSON round trip', () {
      final back = MealSlot.fromJson(slot.toJson());
      expect(back.items, hasLength(3));
      expect(back.drinks.single.name, 'Water');
    });
  });

  group('Plan period', () {
    test('a plan with no duration never expires', () {
      const s = NutritionSettings();
      expect(s.isPlanActive(DateTime(2030, 1, 1)), isTrue);
      expect(s.planEnd, isNull);
      expect(s.daysLeft(), isNull);
    });

    test('a week runs from its start day through the seventh day', () {
      const s = NutritionSettings(
          planStartDay: '2026-04-01', planDurationDays: 7);
      expect(s.planEnd, DateTime(2026, 4, 7));
      expect(s.isPlanActive(DateTime(2026, 4, 1)), isTrue);
      expect(s.isPlanActive(DateTime(2026, 4, 7, 23, 30)), isTrue);
      expect(s.isPlanActive(DateTime(2026, 4, 8)), isFalse);
      expect(s.daysLeft(DateTime(2026, 4, 1)), 7);
      expect(s.daysLeft(DateTime(2026, 4, 7)), 1);
      expect(s.daysLeft(DateTime(2026, 4, 20)), 0);
    });

    test('a month crosses the month boundary', () {
      const s = NutritionSettings(
          planStartDay: '2026-04-20', planDurationDays: 30);
      expect(s.planEnd, DateTime(2026, 5, 19));
      expect(s.isPlanActive(DateTime(2026, 5, 19)), isTrue);
      expect(s.isPlanActive(DateTime(2026, 5, 20)), isFalse);
    });

    test('a timestamp from the server is read as a day', () {
      final s = NutritionSettings.fromJson(
          {'planStartDay': '2026-04-01T00:00:00.000Z', 'planDurationDays': 14});
      expect(s.planStartDay, '2026-04-01');
      expect(s.planEnd, DateTime(2026, 4, 14));
    });

    test('choosing a duration starts it today and survives a restart',
        () async {
      final repo = _repo();
      final first = NutritionController(repo);
      await first.load();
      expect(first.planDurationDays, NutritionSettings.ongoing);

      await first.setPlanDuration(14);
      expect(first.planDurationDays, 14);
      expect(first.planActive, isTrue);
      expect(first.planDaysLeft, 14);

      final second = NutritionController(repo);
      await second.load();
      expect(second.planDurationDays, 14);
      expect(second.planActive, isTrue);
    });

    test('going back to no end date clears the start day', () async {
      final c = NutritionController(_repo());
      await c.load();
      await c.setPlanDuration(7);
      await c.setPlanDuration(NutritionSettings.ongoing);
      expect(c.planEnd, isNull);
      expect(c.planActive, isTrue);
      expect(c.settings.planStartDay, isEmpty);
    });
  });

  group('Meals per day', () {
    test('regenerates the schedule and keeps names and ingredients', () async {
      final repo = _repo();
      final meals = MealScheduleController(repo);
      await meals.init();
      expect(meals.mealsPerDay, 5);

      // Give the first meal some detail, then ask for fewer meals.
      await meals.upsert(meals.slots.first.copyWith(
        name: 'Big breakfast',
        items: const [MealItem(name: 'Eggs', amount: '3')],
      ));
      await meals.setMealsPerDay(3);

      expect(meals.mealsPerDay, 3);
      expect(meals.slots.first.name, 'Big breakfast');
      expect(meals.slots.first.items.single.name, 'Eggs');
      expect(meals.slots.first.kind, MealKind.breakfast);
      expect(meals.slots.last.kind, MealKind.dinner);
      // Ordered, and never closer together than an hour.
      for (var i = 1; i < meals.slots.length; i++) {
        expect(meals.slots[i].minuteOfDay - meals.slots[i - 1].minuteOfDay,
            greaterThanOrEqualTo(60));
      }
    });

    test('the count is clamped to what a day can hold', () async {
      final meals = MealScheduleController(_repo());
      await meals.init();

      await meals.setMealsPerDay(99);
      expect(meals.mealsPerDay,
          lessThanOrEqualTo(NutritionSettings.maxMealsPerDay));

      await meals.setMealsPerDay(0);
      expect(meals.mealsPerDay,
          greaterThanOrEqualTo(NutritionSettings.minMealsPerDay));
    });

    test('the new schedule is persisted', () async {
      final repo = _repo();
      final first = MealScheduleController(repo);
      await first.init();
      await first.setMealsPerDay(4);

      final second = MealScheduleController(repo);
      await second.init();
      expect(second.mealsPerDay, 4);
    });
  });

  group('Coach plan with items and a duration', () {
    Map<String, dynamic> planJson({int duration = 14}) => {
          'id': 'plan-7',
          'waterTargetGlasses': 10,
          'durationDays': duration,
          'note': 'Two weeks, high protein',
          'coachName': 'Sami',
          'mealSchedule': [
            {
              'id': 'c_breakfast',
              'kind': 'breakfast',
              'minuteOfDay': 420,
              'items': [
                {'name': 'Oats', 'amount': '60 g'},
                {'name': 'Milk', 'kind': 'drink'},
              ],
            },
            {'id': 'c_dinner', 'kind': 'dinner', 'minuteOfDay': 1140},
          ],
        };

    test('carries the duration and the ingredients through', () {
      final plan = CoachNutritionPlan.fromJson(planJson());
      expect(plan.durationDays, 14);
      expect(plan.mealSchedule.first.items, hasLength(2));
      expect(plan.mealSchedule.first.drinks.single.name, 'Milk');
    });

    test('applying it starts the period on the member\'s side', () async {
      final repo = _repo(_serverReturning({
        'settings': {'waterTargetGlasses': 8, 'glassMl': 250},
        'today': {'day': '2026-04-01', 'waterGlasses': 0, 'mealsDone': []},
        'coachPlan': planJson(),
      }));
      final nutrition = NutritionController(repo);
      final meals = MealScheduleController(repo);
      await nutrition.load();
      await meals.init();

      final applied = await applyCoachNutritionPlanIfNew(
          nutrition: nutrition, meals: meals);

      expect(applied, isTrue);
      expect(nutrition.planDurationDays, 14);
      expect(nutrition.planActive, isTrue);
      expect(nutrition.waterTargetGlasses, 10);
      expect(meals.slots.first.items, hasLength(2));
    });

    test('a plan with no duration leaves the member\'s period alone', () async {
      final repo = _repo(_serverReturning({
        'settings': {'waterTargetGlasses': 8, 'glassMl': 250},
        'today': {'day': '2026-04-01', 'waterGlasses': 0, 'mealsDone': []},
        'coachPlan': planJson(duration: 0),
      }));
      final nutrition = NutritionController(repo);
      final meals = MealScheduleController(repo);
      await nutrition.load();
      await meals.init();
      await nutrition.setPlanDuration(7);

      await applyCoachNutritionPlanIfNew(nutrition: nutrition, meals: meals);
      expect(nutrition.planDurationDays, 7);
    });
  });
}
