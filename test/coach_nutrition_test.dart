import 'dart:convert';

import 'package:arete/data/api/api_client.dart';
import 'package:arete/data/models/meal_slot.dart';
import 'package:arete/data/models/nutrition.dart';
import 'package:arete/data/repositories/nutrition_repository.dart';
import 'package:arete/state/coach_nutrition_controller.dart';
import 'package:arete/state/coach_plan_sync.dart';
import 'package:arete/state/meal_schedule_controller.dart';
import 'package:arete/state/nutrition_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The plan payload the server sends for a member.
Map<String, dynamic> _planJson({
  String id = 'plan-1',
  int? waterTarget = 12,
  String note = 'Protein with every meal',
}) =>
    {
      'id': id,
      'waterTargetGlasses': waterTarget,
      'note': note,
      'coachName': 'Sami',
      'createdAt': '2026-04-01T09:00:00.000Z',
      'mealSchedule': [
        {
          'id': 'coach_breakfast',
          'kind': 'breakfast',
          'minuteOfDay': 6 * 60 + 30,
          'note': 'Eggs + oats',
        },
        {'id': 'coach_lunch', 'kind': 'lunch', 'minuteOfDay': 12 * 60},
        {'id': 'coach_dinner', 'kind': 'dinner', 'minuteOfDay': 19 * 60},
      ],
    };

MockClient _serverReturning(Map<String, dynamic> body,
        {List<http.Request>? sent, int status = 200}) =>
    MockClient((request) async {
      sent?.add(request);
      return http.Response(jsonEncode(body), status,
          headers: {'content-type': 'application/json'});
    });

NutritionRepository _repo(http.Client client) =>
    NutritionRepository(ApiClient(httpClient: client));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The meal controller re-writes the OS schedule whenever it changes; stub the
  // plugin channel so that is a no-op here.
  const notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel, (call) async {
      // The plugin types a few of these as bool.
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

  group('CoachNutritionPlan', () {
    test('every slot is marked as coming from the coach', () {
      final plan = CoachNutritionPlan.fromJson(_planJson());
      expect(plan.id, 'plan-1');
      expect(plan.coachName, 'Sami');
      expect(plan.waterTargetGlasses, 12);
      expect(plan.mealSchedule, hasLength(3));
      expect(plan.mealSchedule.every((s) => s.source == MealSource.coach),
          isTrue);
      expect(plan.mealSchedule.first.kind, MealKind.breakfast);
      expect(plan.mealSchedule.first.note, 'Eggs + oats');
    });

    test('a plan with no water goal leaves the member\'s own goal alone', () {
      final plan =
          CoachNutritionPlan.fromJson(_planJson(waterTarget: null));
      expect(plan.waterTargetGlasses, isNull);
    });
  });

  group('NutritionController · coach plan', () {
    NutritionController controllerWithPlan([Map<String, dynamic>? plan]) =>
        NutritionController(_repo(_serverReturning({
          'settings': {'waterTargetGlasses': 8, 'glassMl': 250},
          'today': {'day': '2026-04-01', 'waterGlasses': 0, 'mealsDone': []},
          'coachPlan': plan ?? _planJson(),
        })));

    test('an incoming plan is flagged until it is applied', () async {
      final c = controllerWithPlan();
      await c.load();
      expect(c.coachPlan, isNotNull);
      expect(c.hasUnappliedCoachPlan, isTrue);

      await c.markCoachPlanApplied(c.coachPlan!.id);
      expect(c.hasUnappliedCoachPlan, isFalse);
    });

    test('the applied plan is remembered across restarts', () async {
      final repo = _repo(_serverReturning({
        'settings': {'waterTargetGlasses': 8, 'glassMl': 250},
        'today': {'day': '2026-04-01', 'waterGlasses': 0, 'mealsDone': []},
        'coachPlan': _planJson(),
      }));

      final first = NutritionController(repo);
      await first.load();
      await first.markCoachPlanApplied('plan-1');

      final second = NutritionController(repo);
      await second.load();
      expect(second.hasUnappliedCoachPlan, isFalse);

      // A newer plan from the coach is pending again.
      final third = NutritionController(_repo(_serverReturning({
        'settings': {'waterTargetGlasses': 8, 'glassMl': 250},
        'today': {'day': '2026-04-01', 'waterGlasses': 0, 'mealsDone': []},
        'coachPlan': _planJson(id: 'plan-2'),
      })));
      await third.load();
      expect(third.hasUnappliedCoachPlan, isTrue);
    });

    test('no plan means nothing to apply', () async {
      final c = NutritionController(_repo(_serverReturning({
        'settings': {'waterTargetGlasses': 8, 'glassMl': 250},
        'today': {'day': '2026-04-01', 'waterGlasses': 0, 'mealsDone': []},
        'coachPlan': null,
      })));
      await c.load();
      expect(c.coachPlan, isNull);
      expect(c.hasUnappliedCoachPlan, isFalse);
    });
  });

  group('applyCoachNutritionPlan', () {
    test('replaces the schedule, sets the goal and only lands once', () async {
      final repo = _repo(_serverReturning({
        'settings': {'waterTargetGlasses': 8, 'glassMl': 250},
        'today': {'day': '2026-04-01', 'waterGlasses': 0, 'mealsDone': []},
        'coachPlan': _planJson(),
      }));
      final nutrition = NutritionController(repo);
      final meals = MealScheduleController(repo);
      await nutrition.load();
      await meals.init();
      expect(meals.slots, hasLength(5)); // the app's default schedule

      final applied = await applyCoachNutritionPlanIfNew(
        nutrition: nutrition,
        meals: meals,
      );

      expect(applied, isTrue);
      expect(meals.slots, hasLength(3));
      expect(meals.slots.every((s) => s.source == MealSource.coach), isTrue);
      expect(meals.slots.first.minuteOfDay, 6 * 60 + 30);
      expect(nutrition.waterTargetGlasses, 12);
      expect(nutrition.hasUnappliedCoachPlan, isFalse);

      // Running again does nothing, so a member's later edits stand.
      await meals.addSnack(minuteOfDay: 15 * 60);
      final second = await applyCoachNutritionPlanIfNew(
        nutrition: nutrition,
        meals: meals,
      );
      expect(second, isFalse);
      expect(meals.slots, hasLength(4));
    });

    test('restoring the plan brings the coach schedule back', () async {
      final repo = _repo(_serverReturning({
        'settings': {'waterTargetGlasses': 8, 'glassMl': 250},
        'today': {'day': '2026-04-01', 'waterGlasses': 0, 'mealsDone': []},
        'coachPlan': _planJson(),
      }));
      final nutrition = NutritionController(repo);
      final meals = MealScheduleController(repo);
      await nutrition.load();
      await meals.init();
      await applyCoachNutritionPlanIfNew(nutrition: nutrition, meals: meals);

      await meals.removeSlot('coach_lunch');
      expect(meals.slots, hasLength(2));

      final restored =
          await applyCoachNutritionPlan(nutrition: nutrition, meals: meals);
      expect(restored, isTrue);
      expect(meals.slots, hasLength(3));
    });

    test('a plan without a water goal leaves the member\'s goal untouched',
        () async {
      final repo = _repo(_serverReturning({
        'settings': {'waterTargetGlasses': 8, 'glassMl': 250},
        'today': {'day': '2026-04-01', 'waterGlasses': 0, 'mealsDone': []},
        'coachPlan': _planJson(waterTarget: null),
      }));
      final nutrition = NutritionController(repo);
      final meals = MealScheduleController(repo);
      await nutrition.load();
      await meals.init();
      await nutrition.setTargetGlasses(6);

      await applyCoachNutritionPlanIfNew(nutrition: nutrition, meals: meals);
      expect(nutrition.waterTargetGlasses, 6);
      expect(meals.slots, hasLength(3));
    });
  });

  group('CoachNutritionController', () {
    test('starts from the coach\'s last plan when there is one', () async {
      final c = CoachNutritionController(ApiClient(
        httpClient: _serverReturning({
          'plan': _planJson(),
          'current': {'waterTargetGlasses': 8, 'glassMl': 250},
        }),
      ));
      await c.load('member-1');

      expect(c.plan, isNotNull);
      expect(c.startingWaterTarget(), 12);
      expect(c.startingSchedule(), hasLength(3));
    });

    test('starts from what the trainee follows when no plan was sent',
        () async {
      final c = CoachNutritionController(ApiClient(
        httpClient: _serverReturning({
          'plan': null,
          'current': {
            'waterTargetGlasses': 9,
            'glassMl': 250,
            'mealSchedule': [
              {'id': 'own_lunch', 'kind': 'lunch', 'minuteOfDay': 780},
            ],
          },
        }),
      ));
      await c.load('member-1');

      expect(c.plan, isNull);
      expect(c.startingWaterTarget(), 9);
      final schedule = c.startingSchedule();
      expect(schedule, hasLength(1));
      expect(schedule.single.source, MealSource.coach);
    });

    test('falls back to the default schedule for a brand-new trainee',
        () async {
      final c = CoachNutritionController(
          ApiClient(httpClient: _serverReturning({'plan': null, 'current': {}})));
      await c.load('member-1');
      expect(c.startingSchedule(), hasLength(5));
      expect(c.startingWaterTarget(), NutritionSettings.defaultTargetGlasses);
    });

    test('sending posts the schedule and reports failures', () async {
      final sent = <http.Request>[];
      final ok = CoachNutritionController(ApiClient(
        httpClient: _serverReturning({'plan': _planJson(id: 'plan-9')},
            sent: sent),
      ));
      await ok.load('member-1');
      sent.clear();

      final error = await ok.send(
        mealSchedule: MealSlot.defaults(),
        waterTargetGlasses: 10,
        note: 'Cut the late carbs',
      );
      expect(error, isNull);
      expect(ok.plan?.id, 'plan-9');
      expect(sent, hasLength(1));
      final body = jsonDecode(sent.single.body) as Map<String, dynamic>;
      expect(body['waterTargetGlasses'], 10);
      expect(body['note'], 'Cut the late carbs');
      expect((body['mealSchedule'] as List), hasLength(5));

      final refused = CoachNutritionController(ApiClient(
        httpClient: _serverReturning({'error': 'That member is not your client'},
            status: 403),
      ));
      await refused.load('member-2');
      final message = await refused.send(
        mealSchedule: MealSlot.defaults(),
        waterTargetGlasses: 8,
      );
      expect(message, isNotNull);
    });

    test('an empty schedule is refused before it reaches the server', () async {
      final sent = <http.Request>[];
      final c = CoachNutritionController(
          ApiClient(httpClient: _serverReturning({'plan': null}, sent: sent)));
      await c.load('member-1');
      sent.clear();

      expect(await c.send(mealSchedule: const [], waterTargetGlasses: 8),
          isNotNull);
      expect(sent, isEmpty);
    });
  });
}
