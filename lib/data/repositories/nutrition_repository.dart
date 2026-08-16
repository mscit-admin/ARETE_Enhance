import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../models/meal_slot.dart';
import '../models/nutrition.dart';

/// Storage for the water target, the meal schedule and the daily intake.
///
/// Server-first with a local mirror: every read falls back to the cache and
/// every write updates the cache before it tries the network, so the Meals &
/// Drinks screen works offline — and against a server that has not run the
/// nutrition migration yet.
class NutritionRepository {
  NutritionRepository(this._client);

  final ApiClient _client;

  static const _kSettings = 'nutrition_settings';
  static const _kDayPrefix = 'nutrition_day_';
  static const _kCoachPlan = 'nutrition_coach_plan';
  static const _kAppliedPlan = 'nutrition_coach_plan_applied';

  // ---- reads ----

  /// Settings + the given day's intake. Never throws.
  Future<NutritionSnapshot> load(String day) async {
    final cached = await _cachedSnapshot(day);
    try {
      final json = await _client.get('/api/app/nutrition?day=$day')
          as Map<String, dynamic>;
      final settings = NutritionSettings.fromJson(
          (json['settings'] as Map?)?.cast<String, dynamic>() ?? const {});
      final today = NutritionDay.fromJson(
          (json['today'] as Map?)?.cast<String, dynamic>() ?? {'day': day});
      final rawPlan = (json['coachPlan'] as Map?)?.cast<String, dynamic>();
      final coachPlan = rawPlan == null || (rawPlan['id'] ?? '').toString().isEmpty
          ? null
          : CoachNutritionPlan.fromJson(rawPlan);
      // An un-migrated server answers with defaults; keep the local copy so a
      // target the member already chose is not silently reset.
      if (json['unavailable'] == true) return cached;
      await _cacheSettings(settings);
      await _cacheDay(today);
      await _cacheCoachPlan(coachPlan);
      return NutritionSnapshot(
          settings: settings, today: today, coachPlan: coachPlan);
    } catch (_) {
      return cached;
    }
  }

  Future<NutritionSnapshot> _cachedSnapshot(String day) async {
    return NutritionSnapshot(
      settings: await loadCachedSettings(),
      today: await _cachedDay(day),
      coachPlan: await _cachedCoachPlan(),
    );
  }

  Future<CoachNutritionPlan?> _cachedCoachPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCoachPlan);
      if (raw == null || raw.isEmpty) return null;
      return CoachNutritionPlan.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheCoachPlan(CoachNutritionPlan? plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (plan == null) {
        await prefs.remove(_kCoachPlan);
      } else {
        await prefs.setString(_kCoachPlan, jsonEncode(plan.toJson()));
      }
    } catch (_) {}
  }

  /// The id of the coach plan the app has already applied, so a plan is only
  /// pushed onto the member's schedule once.
  Future<String> loadAppliedCoachPlanId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kAppliedPlan) ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> saveAppliedCoachPlanId(String planId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAppliedPlan, planId);
    } catch (_) {}
  }

  /// The cached settings alone — used by the reminder controllers at startup,
  /// before (or without) a network round trip.
  Future<NutritionSettings> loadCachedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSettings);
      if (raw == null || raw.isEmpty) return const NutritionSettings();
      return NutritionSettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const NutritionSettings();
    }
  }

  Future<NutritionDay> _cachedDay(String day) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_kDayPrefix$day');
      if (raw == null || raw.isEmpty) return NutritionDay(day: day);
      return NutritionDay.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return NutritionDay(day: day);
    }
  }

  // ---- writes (cache first, then best-effort sync) ----

  /// Store the water goal. The meal schedule is left untouched server-side.
  Future<void> saveWaterSettings({
    required int waterTargetGlasses,
    required int glassMl,
  }) async {
    final current = await loadCachedSettings();
    final next = current.copyWith(
      waterTargetGlasses: waterTargetGlasses,
      glassMl: glassMl,
    );
    await _cacheSettings(next);
    await _put({
      'waterTargetGlasses': waterTargetGlasses,
      'glassMl': glassMl,
    });
  }

  /// Store the meal schedule, keeping the water goal as it is.
  Future<void> saveMealSchedule(List<MealSlot> slots) async {
    final current = await loadCachedSettings();
    await _cacheSettings(current.copyWith(mealSchedule: slots));
    await _put({
      'waterTargetGlasses': current.waterTargetGlasses,
      'glassMl': current.glassMl,
      'mealSchedule': [for (final s in slots) s.toJson()],
    });
  }

  Future<void> saveWaterGlasses(String day, int glasses) async {
    final current = await _cachedDay(day);
    await _cacheDay(current.copyWith(waterGlasses: glasses));
    try {
      await _client.post(
        '/api/app/nutrition/water',
        {'day': day, 'glasses': glasses},
        auth: true,
      );
    } catch (_) {
      // Offline — the cached value stands until the next successful sync.
    }
  }

  Future<void> saveMealsDone(String day, Set<String> mealsDone) async {
    final current = await _cachedDay(day);
    await _cacheDay(current.copyWith(mealsDone: mealsDone));
    try {
      await _client.post(
        '/api/app/nutrition/meals',
        {'day': day, 'mealsDone': mealsDone.toList()},
        auth: true,
      );
    } catch (_) {}
  }

  Future<void> _put(Map<String, dynamic> body) async {
    try {
      await _client.put('/api/app/nutrition/settings', body);
    } catch (_) {}
  }

  Future<void> _cacheSettings(NutritionSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSettings, jsonEncode(settings.toJson()));
    } catch (_) {}
  }

  Future<void> _cacheDay(NutritionDay day) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_kDayPrefix${day.day}';
      await prefs.setString(key, jsonEncode(day.toJson()));
      // Only the current day is ever read back, so drop the older entries
      // instead of letting one accumulate per day forever.
      for (final stale in prefs.getKeys()
          .where((k) => k.startsWith(_kDayPrefix) && k != key)
          .toList()) {
        await prefs.remove(stale);
      }
    } catch (_) {}
  }

  /// Forget this account's cached nutrition data (called on sign-out so the
  /// next account does not briefly see the previous member's goal).
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kSettings);
      await prefs.remove(_kCoachPlan);
      await prefs.remove(_kAppliedPlan);
      for (final key
          in prefs.getKeys().where((k) => k.startsWith(_kDayPrefix)).toList()) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}
