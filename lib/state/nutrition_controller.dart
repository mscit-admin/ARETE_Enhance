import 'package:flutter/foundation.dart';

import '../core/constants/enums.dart';
import '../data/models/nutrition.dart';
import '../data/repositories/nutrition_repository.dart';
import 'profile_controller.dart';

/// Drives the Food & Drink screen: loads the coach's weekly meal plan and the
/// food library, tracks which day is selected, which planned meals the member
/// has ticked off, and any extra meals they logged themselves. Water is logged
/// through the shared [ProfileController] so it stays in sync with the Home
/// activity ring.
class NutritionController extends ChangeNotifier {
  NutritionController(this._repo, this._profile);

  final NutritionRepository _repo;
  final ProfileController _profile;

  LoadStatus _status = LoadStatus.idle;
  MealPlan? _plan;
  List<FoodItem> _library = const [];

  /// 1 = Monday … 7 = Sunday (matches [DateTime.weekday]).
  int _selectedWeekday = DateTime.now().weekday;

  /// Ticked planned meals, keyed "$weekday:$mealId".
  final Set<String> _eaten = {};

  /// Member-logged extra meals, keyed by weekday.
  final Map<int, List<LoggedMeal>> _logged = {};

  int _idSeq = 0;

  LoadStatus get status => _status;
  MealPlan? get plan => _plan;
  List<FoodItem> get library => _library;
  int get selectedWeekday => _selectedWeekday;

  /// The plan for the currently selected day (may be null if none assigned).
  DayMealPlan? get selectedDay => _plan?.dayFor(_selectedWeekday);

  Future<void> load() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _plan = await _repo.getMealPlan();
      _library = await _repo.getFoodLibrary();
      _status = LoadStatus.ready;
    } catch (_) {
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  void selectDay(int weekday) {
    if (weekday == _selectedWeekday) return;
    _selectedWeekday = weekday;
    notifyListeners();
  }

  // ---- Planned meals ----

  String _eatenKey(int weekday, String mealId) => '$weekday:$mealId';

  bool isEaten(int weekday, String mealId) =>
      _eaten.contains(_eatenKey(weekday, mealId));

  void toggleEaten(int weekday, String mealId) {
    final key = _eatenKey(weekday, mealId);
    if (!_eaten.remove(key)) _eaten.add(key);
    notifyListeners();
  }

  // ---- Extra (self-logged) meals ----

  List<LoggedMeal> loggedFor(int weekday, MealType type) =>
      (_logged[weekday] ?? const [])
          .where((m) => m.type == type)
          .toList(growable: false);

  void addFromLibrary(int weekday, MealType type, FoodItem food) {
    final meal = LoggedMeal.fromFood(type, food, 'log_${_idSeq++}');
    _logged.putIfAbsent(weekday, () => []).add(meal);
    notifyListeners();
  }

  void addCustom(int weekday, MealType type, String name, int kcal) {
    final meal = LoggedMeal(
      id: 'log_${_idSeq++}',
      type: type,
      name: name,
      kcal: kcal,
    );
    _logged.putIfAbsent(weekday, () => []).add(meal);
    notifyListeners();
  }

  void removeLogged(int weekday, String id) {
    _logged[weekday]?.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // ---- Daily totals for the selected day ----

  /// Calories consumed = ticked planned meals + all self-logged meals.
  int get consumedKcal {
    var total = 0;
    final day = selectedDay;
    if (day != null) {
      for (final m in day.meals) {
        if (isEaten(_selectedWeekday, m.id)) total += m.kcal;
      }
    }
    for (final m in _logged[_selectedWeekday] ?? const <LoggedMeal>[]) {
      total += m.kcal;
    }
    return total;
  }

  int get targetKcal => selectedDay?.targetKcal ?? 0;

  int get consumedProteinG => _macro((m) => m.proteinG, (l) => l.proteinG);
  int get consumedCarbsG => _macro((m) => m.carbsG, (l) => l.carbsG);
  int get consumedFatG => _macro((m) => m.fatG, (l) => l.fatG);

  int _macro(int Function(PlannedMeal) planned, int Function(LoggedMeal) log) {
    var total = 0;
    final day = selectedDay;
    if (day != null) {
      for (final m in day.meals) {
        if (isEaten(_selectedWeekday, m.id)) total += planned(m);
      }
    }
    for (final m in _logged[_selectedWeekday] ?? const <LoggedMeal>[]) {
      total += log(m);
    }
    return total;
  }

  double get kcalProgress =>
      targetKcal == 0 ? 0 : (consumedKcal / targetKcal).clamp(0.0, 1.0);

  /// How many of today's planned meals have been ticked off.
  int get eatenCount {
    final day = selectedDay;
    if (day == null) return 0;
    return day.meals.where((m) => isEaten(_selectedWeekday, m.id)).length;
  }

  int get plannedCount => selectedDay?.meals.length ?? 0;

  // ---- Water (delegates to the shared profile stats) ----

  int get waterGlasses => _profile.member?.dailyStats.waterGlasses ?? 0;
  int get waterTarget => _profile.member?.dailyStats.waterTargetGlasses ?? 0;

  Future<void> logWater() => _profile.logWater();

  void clear() {
    _plan = null;
    _library = const [];
    _eaten.clear();
    _logged.clear();
    _selectedWeekday = DateTime.now().weekday;
    _status = LoadStatus.idle;
    notifyListeners();
  }
}
