import 'package:flutter/foundation.dart';

import '../data/models/meal_slot.dart';
import '../data/models/nutrition.dart';
import '../data/repositories/nutrition_repository.dart';

/// The single source of truth for eating and drinking: the daily water goal,
/// how much has been drunk today, and which meals have been ticked off.
///
/// The water reminders read their target from here, the home ring reads today's
/// progress from here, and the Meals & Drinks screen edits it.
class NutritionController extends ChangeNotifier {
  NutritionController(this._repo);

  final NutritionRepository _repo;

  NutritionSettings _settings = const NutritionSettings();
  NutritionDay _today = NutritionDay(day: NutritionDay.keyFor(DateTime.now()));
  bool _loaded = false;

  NutritionSettings get settings => _settings;
  NutritionDay get today => _today;
  bool get loaded => _loaded;

  int get waterTargetGlasses => _settings.waterTargetGlasses;
  int get glassMl => _settings.glassMl;
  int get waterGlasses => _today.waterGlasses;

  double get litresDrunk => waterGlasses * glassMl / 1000;
  double get litresTarget => _settings.targetLitres;

  /// 0..1, clamped — what the ring on the home screen shows.
  double get waterProgress => waterTargetGlasses == 0
      ? 0
      : (waterGlasses / waterTargetGlasses).clamp(0.0, 1.0);

  int get glassesLeft {
    final left = waterTargetGlasses - waterGlasses;
    return left < 0 ? 0 : left;
  }

  Set<String> get mealsDone => _today.mealsDone;

  bool isMealDone(String id) => _today.isDone(id);

  /// Load settings and today's intake (server first, cache otherwise).
  Future<void> load() async {
    final day = NutritionDay.keyFor(DateTime.now());
    final snapshot = await _repo.load(day);
    _settings = snapshot.settings;
    _today = snapshot.today.day == day ? snapshot.today : NutritionDay(day: day);
    _loaded = true;
    notifyListeners();
  }

  /// Roll over to a new day when the app is left open past midnight. Returns
  /// true when the day changed.
  bool _rolloverIfNeeded() {
    final day = NutritionDay.keyFor(DateTime.now());
    if (day == _today.day) return false;
    _today = NutritionDay(day: day);
    return true;
  }

  // ---- water ----

  Future<void> logGlass() => _setGlasses(waterGlasses + 1);

  Future<void> removeGlass() => _setGlasses(waterGlasses - 1);

  Future<void> _setGlasses(int glasses) async {
    _rolloverIfNeeded();
    final next = glasses.clamp(0, 60);
    if (next == _today.waterGlasses) return;
    _today = _today.copyWith(waterGlasses: next);
    notifyListeners();
    await _repo.saveWaterGlasses(_today.day, next);
  }

  /// Change the daily goal. The water reminders rebuild themselves from it.
  Future<void> setTargetGlasses(int glasses) async {
    final next = glasses.clamp(
      NutritionSettings.minTargetGlasses,
      NutritionSettings.maxTargetGlasses,
    );
    if (next == _settings.waterTargetGlasses) return;
    _settings = _settings.copyWith(waterTargetGlasses: next);
    notifyListeners();
    await _repo.saveWaterSettings(
      waterTargetGlasses: next,
      glassMl: _settings.glassMl,
    );
  }

  Future<void> setGlassMl(int ml) async {
    if (ml == _settings.glassMl) return;
    _settings = _settings.copyWith(glassMl: ml);
    notifyListeners();
    await _repo.saveWaterSettings(
      waterTargetGlasses: _settings.waterTargetGlasses,
      glassMl: ml,
    );
  }

  // ---- meals ----

  /// Tick a meal off (or untick it) for today.
  Future<void> toggleMealDone(String mealId) async {
    _rolloverIfNeeded();
    final next = {..._today.mealsDone};
    if (!next.remove(mealId)) next.add(mealId);
    _today = _today.copyWith(mealsDone: next);
    notifyListeners();
    await _repo.saveMealsDone(_today.day, next);
  }

  /// How many of [slots] have been eaten today.
  int doneCount(List<MealSlot> slots) =>
      slots.where((s) => s.enabled && isMealDone(s.id)).length;

  /// Drop everything on sign-out so the next account starts clean — including
  /// the local cache, which is not account-scoped.
  void clear() {
    _settings = const NutritionSettings();
    _today = NutritionDay(day: NutritionDay.keyFor(DateTime.now()));
    _loaded = false;
    notifyListeners();
    _repo.clearCache();
  }
}
