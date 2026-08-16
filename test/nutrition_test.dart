import 'dart:convert';

import 'package:arete/data/api/api_client.dart';
import 'package:arete/data/models/meal_slot.dart';
import 'package:arete/data/models/nutrition.dart';
import 'package:arete/data/repositories/nutrition_repository.dart';
import 'package:arete/state/nutrition_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A client that answers every call with [body], recording what it was sent.
MockClient _serverReturning(
  Map<String, dynamic> body, {
  List<http.Request>? sent,
}) =>
    MockClient((request) async {
      sent?.add(request);
      return http.Response(jsonEncode(body), 200,
          headers: {'content-type': 'application/json'});
    });

/// A server that is down (or the phone is offline).
MockClient get _serverDown =>
    MockClient((_) async => http.Response('{"error":"boom"}', 500,
        headers: {'content-type': 'application/json'}));

NutritionRepository _repo(http.Client client) =>
    NutritionRepository(ApiClient(httpClient: client));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('NutritionSettings', () {
    test('round trips, schedule included', () {
      final settings = NutritionSettings(
        waterTargetGlasses: 10,
        glassMl: 330,
        mealSchedule: MealSlot.defaults(),
      );
      final back = NutritionSettings.fromJson(settings.toJson());
      expect(back.waterTargetGlasses, 10);
      expect(back.glassMl, 330);
      expect(back.mealSchedule, hasLength(5));
      expect(back.mealSchedule!.first.kind, MealKind.breakfast);
    });

    test('out-of-range values are clamped, missing ones defaulted', () {
      final tooMany = NutritionSettings.fromJson({'waterTargetGlasses': 500});
      expect(tooMany.waterTargetGlasses, NutritionSettings.maxTargetGlasses);
      final tooFew = NutritionSettings.fromJson({'waterTargetGlasses': 0});
      expect(tooFew.waterTargetGlasses, NutritionSettings.minTargetGlasses);
      final empty = NutritionSettings.fromJson({});
      expect(empty.waterTargetGlasses, NutritionSettings.defaultTargetGlasses);
      expect(empty.glassMl, NutritionSettings.defaultGlassMl);
      expect(empty.mealSchedule, isNull);
    });

    test('the litre goal follows the glass size', () {
      const s = NutritionSettings(waterTargetGlasses: 8, glassMl: 250);
      expect(s.targetLitres, 2.0);
      expect(s.copyWith(glassMl: 500).targetLitres, 4.0);
    });
  });

  group('NutritionDay', () {
    test('the day key is a zero-padded local date', () {
      expect(NutritionDay.keyFor(DateTime(2026, 3, 7)), '2026-03-07');
      expect(NutritionDay.keyFor(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('round trips the ticked meals', () {
      const day = NutritionDay(
          day: '2026-03-07', waterGlasses: 5, mealsDone: {'lunch', 'dinner'});
      final back = NutritionDay.fromJson(day.toJson());
      expect(back.waterGlasses, 5);
      expect(back.mealsDone, {'lunch', 'dinner'});
      expect(back.isDone('lunch'), isTrue);
      expect(back.isDone('breakfast'), isFalse);
    });
  });

  group('NutritionRepository', () {
    test('reads the server answer and caches it', () async {
      final repo = _repo(_serverReturning({
        'settings': {'waterTargetGlasses': 12, 'glassMl': 500},
        'today': {'day': '2026-03-07', 'waterGlasses': 3, 'mealsDone': ['lunch']},
      }));

      final snapshot = await repo.load('2026-03-07');
      expect(snapshot.settings.waterTargetGlasses, 12);
      expect(snapshot.today.waterGlasses, 3);

      // The cache now answers on its own, without the network.
      final cached = await _repo(_serverDown).load('2026-03-07');
      expect(cached.settings.waterTargetGlasses, 12);
      expect(cached.today.waterGlasses, 3);
      expect(cached.today.mealsDone, {'lunch'});
    });

    test('an offline write still updates the local copy', () async {
      final repo = _repo(_serverDown);
      await repo.saveWaterSettings(waterTargetGlasses: 9, glassMl: 200);
      await repo.saveWaterGlasses('2026-03-07', 4);

      final snapshot = await repo.load('2026-03-07');
      expect(snapshot.settings.waterTargetGlasses, 9);
      expect(snapshot.settings.glassMl, 200);
      expect(snapshot.today.waterGlasses, 4);
    });

    test('an un-migrated server does not reset a goal the member chose',
        () async {
      await _repo(_serverDown)
          .saveWaterSettings(waterTargetGlasses: 14, glassMl: 250);

      // The endpoint exists but the tables do not: it answers with defaults
      // and flags itself unavailable.
      final snapshot = await _repo(_serverReturning({
        'settings': {'waterTargetGlasses': 8, 'glassMl': 250},
        'today': {'day': '2026-03-07', 'waterGlasses': 0, 'mealsDone': []},
        'unavailable': true,
      })).load('2026-03-07');

      expect(snapshot.settings.waterTargetGlasses, 14);
    });

    test('the water goal and the meal schedule do not overwrite each other',
        () async {
      final repo = _repo(_serverDown);
      await repo.saveMealSchedule(MealSlot.defaults());
      await repo.saveWaterSettings(waterTargetGlasses: 11, glassMl: 330);

      final settings = await repo.loadCachedSettings();
      expect(settings.waterTargetGlasses, 11);
      expect(settings.mealSchedule, hasLength(5));
    });

    test('saving the schedule sends it to the server with the water goal',
        () async {
      final sent = <http.Request>[];
      final repo = _repo(_serverReturning({'settings': {}}, sent: sent));
      await repo.saveWaterSettings(waterTargetGlasses: 7, glassMl: 250);
      sent.clear();

      await repo.saveMealSchedule(MealSlot.defaults());
      expect(sent, hasLength(1));
      final body = jsonDecode(sent.single.body) as Map<String, dynamic>;
      expect(body['waterTargetGlasses'], 7);
      expect((body['mealSchedule'] as List), hasLength(5));
    });
  });

  group('NutritionController', () {
    test('logging and removing glasses stays inside the day', () async {
      final c = NutritionController(_repo(_serverDown));
      await c.load();
      expect(c.waterGlasses, 0);

      await c.logGlass();
      await c.logGlass();
      expect(c.waterGlasses, 2);

      await c.removeGlass();
      expect(c.waterGlasses, 1);
      await c.removeGlass();
      await c.removeGlass(); // already empty — must not go negative
      expect(c.waterGlasses, 0);
    });

    test('intake survives a restart', () async {
      final repo = _repo(_serverDown);
      final first = NutritionController(repo);
      await first.load();
      await first.logGlass();
      await first.setTargetGlasses(10);

      final second = NutritionController(repo);
      await second.load();
      expect(second.waterGlasses, 1);
      expect(second.waterTargetGlasses, 10);
    });

    test('the goal is clamped and drives the litre figures', () async {
      final c = NutritionController(_repo(_serverDown));
      await c.load();

      await c.setTargetGlasses(999);
      expect(c.waterTargetGlasses, NutritionSettings.maxTargetGlasses);
      await c.setTargetGlasses(-3);
      expect(c.waterTargetGlasses, NutritionSettings.minTargetGlasses);

      await c.setTargetGlasses(8);
      await c.setGlassMl(500);
      await c.logGlass();
      expect(c.litresDrunk, 0.5);
      expect(c.litresTarget, 4.0);
      expect(c.glassesLeft, 7);
    });

    test('progress is clamped once the goal is passed', () async {
      final c = NutritionController(_repo(_serverDown));
      await c.load();
      await c.setTargetGlasses(2);
      await c.logGlass();
      expect(c.waterProgress, 0.5);
      await c.logGlass();
      await c.logGlass();
      expect(c.waterProgress, 1.0);
      expect(c.glassesLeft, 0);
    });

    test('meals are ticked off and counted', () async {
      final c = NutritionController(_repo(_serverDown));
      await c.load();
      final slots = MealSlot.defaults();

      expect(c.doneCount(slots), 0);
      await c.toggleMealDone('lunch');
      await c.toggleMealDone('dinner');
      expect(c.isMealDone('lunch'), isTrue);
      expect(c.doneCount(slots), 2);

      await c.toggleMealDone('lunch'); // untick
      expect(c.isMealDone('lunch'), isFalse);
      expect(c.doneCount(slots), 1);

      // A disabled slot is not counted even when it was ticked earlier.
      final withDisabled = [
        for (final s in slots)
          s.id == 'dinner' ? s.copyWith(enabled: false) : s,
      ];
      expect(c.doneCount(withDisabled), 0);
    });

    test('signing out clears the account\'s data', () async {
      final c = NutritionController(_repo(_serverDown));
      await c.load();
      await c.logGlass();
      await c.setTargetGlasses(12);

      c.clear();
      expect(c.waterGlasses, 0);
      expect(c.waterTargetGlasses, NutritionSettings.defaultTargetGlasses);
      expect(c.loaded, isFalse);
    });

    test('notifies listeners so the reminders can re-time themselves', () async {
      final c = NutritionController(_repo(_serverDown));
      await c.load();
      var notifications = 0;
      c.addListener(() => notifications++);

      await c.setTargetGlasses(11);
      expect(notifications, greaterThan(0));

      final before = notifications;
      await c.setTargetGlasses(11); // unchanged — no needless rebuild
      expect(notifications, before);
    });
  });
}
