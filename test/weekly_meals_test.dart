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

const _mon = DateTime.monday;
const _tue = DateTime.tuesday;
const _wed = DateTime.wednesday;
const _fri = DateTime.friday;

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

  group('MealSlot days', () {
    test('no days at all means every day', () {
      const slot =
          MealSlot(id: 'a', kind: MealKind.lunch, minuteOfDay: 780);
      expect(slot.everyDay, isTrue);
      for (final day in MealSlot.allWeekdays) {
        expect(slot.appliesOn(day), isTrue);
      }
    });

    test('named days limit the meal to them', () {
      const slot = MealSlot(
          id: 'a', kind: MealKind.lunch, minuteOfDay: 780, days: {_mon, _wed});
      expect(slot.everyDay, isFalse);
      expect(slot.appliesOn(_mon), isTrue);
      expect(slot.appliesOn(_wed), isTrue);
      expect(slot.appliesOn(_tue), isFalse);
    });

    test('days survive the JSON round trip and junk is dropped', () {
      const slot = MealSlot(
          id: 'a', kind: MealKind.dinner, minuteOfDay: 1140, days: {_fri});
      expect(MealSlot.fromJson(slot.toJson()).days, {_fri});

      final messy = MealSlot.fromJson({
        'id': 'b',
        'kind': 'lunch',
        'minuteOfDay': 780,
        'days': [1, 9, 0, 'x', 7],
      });
      expect(messy.days, {1, 7});
    });

    test('a schedule written before weekly plans loads as every day', () {
      final old = MealSlot.fromJson(const {
        'id': 'legacy',
        'kind': 'breakfast',
        'minuteOfDay': 450,
      });
      expect(old.days, isEmpty);
      expect(old.everyDay, isTrue);
    });

    test('withId keeps everything but the identity', () {
      const slot = MealSlot(
        id: 'a',
        kind: MealKind.lunch,
        minuteOfDay: 780,
        days: {_mon},
        items: [MealItem(name: 'Rice')],
      );
      final copy = slot.withId('b');
      expect(copy.id, 'b');
      expect(copy.days, {_mon});
      expect(copy.items.single.name, 'Rice');
    });
  });

  group('MealScheduleController · weekly', () {
    test('a daily schedule shows the same meals on every weekday', () async {
      final meals = MealScheduleController(_repo());
      await meals.init();
      expect(meals.weekly, isFalse);
      for (final day in MealSlot.allWeekdays) {
        expect(meals.slotsFor(day), hasLength(5));
      }
    });

    test('turning the week on keeps every meal, and persists', () async {
      final repo = _repo();
      final first = MealScheduleController(repo);
      await first.init();
      await first.setWeekly(true);
      expect(first.slotsFor(_mon), hasLength(5));

      final second = MealScheduleController(repo);
      await second.init();
      expect(second.weekly, isTrue);
    });

    test('meals a day rebuilds one weekday and leaves the rest alone',
        () async {
      final meals = MealScheduleController(_repo());
      await meals.init();
      await meals.setWeekly(true);

      await meals.setMealsPerDay(3, weekday: _mon);

      expect(meals.slotsFor(_mon), hasLength(3));
      expect(meals.slotsFor(_tue), hasLength(5)); // untouched
      expect(meals.slotsFor(_wed), hasLength(5));
    });

    test('copying a day overwrites the target days only', () async {
      final meals = MealScheduleController(_repo());
      await meals.init();
      await meals.setWeekly(true);
      await meals.setMealsPerDay(2, weekday: _mon);
      expect(meals.slotsFor(_mon), hasLength(2));

      await meals.copyDay(_mon, {_wed, _fri});

      expect(meals.slotsFor(_mon), hasLength(2));
      expect(meals.slotsFor(_wed), hasLength(2));
      expect(meals.slotsFor(_fri), hasLength(2));
      expect(meals.slotsFor(_tue), hasLength(5)); // not a target

      // The copies are their own meals, so editing Monday later leaves
      // Wednesday and Friday as they were. Wednesday and Friday deliberately
      // share one meal — the tick-list is keyed by calendar day, not by slot,
      // so one entry can serve both days.
      final monday = meals.slotsFor(_mon).map((s) => s.id).toSet();
      final wednesday = meals.slotsFor(_wed).map((s) => s.id).toSet();
      expect(monday.intersection(wednesday), isEmpty);
      expect(wednesday, meals.slotsFor(_fri).map((s) => s.id).toSet());
    });

    test('copying carries the ingredients across', () async {
      final meals = MealScheduleController(_repo());
      await meals.init();
      await meals.setWeekly(true);
      await meals.setMealsPerDay(2, weekday: _mon);
      await meals.upsert(meals.slotsFor(_mon).first.copyWith(
            name: 'Big breakfast',
            items: const [MealItem(name: 'Oats', amount: '60 g')],
          ));

      await meals.copyDay(_mon, {_tue});

      final copied = meals.slotsFor(_tue).first;
      expect(copied.name, 'Big breakfast');
      expect(copied.items.single.name, 'Oats');
    });

    test('the next meal only looks at today', () async {
      final meals = MealScheduleController(_repo());
      await meals.init();
      await meals.setWeekly(true);
      // A Monday-only breakfast at 07:00.
      await meals.replaceAll([
        const MealSlot(
            id: 'mon_breakfast',
            kind: MealKind.breakfast,
            minuteOfDay: 7 * 60,
            days: {_mon}),
      ]);

      // 2026-04-06 is a Monday, 2026-04-07 a Tuesday.
      expect(meals.nextUpcoming(DateTime(2026, 4, 6, 6)), isNotNull);
      expect(meals.nextUpcoming(DateTime(2026, 4, 7, 6)), isNull);
    });

    test('turning the week back off shows everything again', () async {
      final meals = MealScheduleController(_repo());
      await meals.init();
      await meals.setWeekly(true);
      await meals.replaceAll([
        const MealSlot(
            id: 'a', kind: MealKind.lunch, minuteOfDay: 780, days: {_mon}),
        const MealSlot(
            id: 'b', kind: MealKind.dinner, minuteOfDay: 1140, days: {_tue}),
      ]);
      expect(meals.slotsFor(_mon), hasLength(1));

      await meals.setWeekly(false);
      expect(meals.slots, hasLength(2));
      expect(meals.mealsPerDay, 2);
    });
  });

  group('Coach weekly plan', () {
    test('a plan that names days switches the member to a weekly schedule',
        () async {
      final repo = _repo(_serverReturning({
        'settings': {'waterTargetGlasses': 8, 'glassMl': 250},
        'today': {'day': '2026-04-06', 'waterGlasses': 0, 'mealsDone': []},
        'coachPlan': {
          'id': 'plan-w',
          'durationDays': 7,
          'mealSchedule': [
            {
              'id': 'c_mon',
              'kind': 'lunch',
              'minuteOfDay': 780,
              'days': [1],
            },
            {
              'id': 'c_tue',
              'kind': 'dinner',
              'minuteOfDay': 1140,
              'days': [2],
            },
          ],
        },
      }));
      final nutrition = NutritionController(repo);
      final meals = MealScheduleController(repo);
      await nutrition.load();
      await meals.init();

      await applyCoachNutritionPlanIfNew(nutrition: nutrition, meals: meals);

      expect(meals.weekly, isTrue);
      expect(meals.slotsFor(_mon), hasLength(1));
      expect(meals.slotsFor(_tue), hasLength(1));
      expect(meals.slotsFor(_wed), isEmpty);
    });

    test('a plan without days leaves the member on a daily schedule', () async {
      final repo = _repo(_serverReturning({
        'settings': {'waterTargetGlasses': 8, 'glassMl': 250},
        'today': {'day': '2026-04-06', 'waterGlasses': 0, 'mealsDone': []},
        'coachPlan': {
          'id': 'plan-d',
          'mealSchedule': [
            {'id': 'c_lunch', 'kind': 'lunch', 'minuteOfDay': 780},
          ],
        },
      }));
      final nutrition = NutritionController(repo);
      final meals = MealScheduleController(repo);
      await nutrition.load();
      await meals.init();

      await applyCoachNutritionPlanIfNew(nutrition: nutrition, meals: meals);

      expect(meals.weekly, isFalse);
      expect(meals.slotsFor(_wed), hasLength(1));
    });
  });

  group('NutritionSettings.weeklyMeals', () {
    test('round trips and defaults to a daily plan', () {
      expect(const NutritionSettings().weeklyMeals, isFalse);
      const weekly = NutritionSettings(weeklyMeals: true);
      expect(NutritionSettings.fromJson(weekly.toJson()).weeklyMeals, isTrue);
      expect(NutritionSettings.fromJson(const {}).weeklyMeals, isFalse);
    });
  });
}
