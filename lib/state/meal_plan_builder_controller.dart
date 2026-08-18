import 'package:flutter/foundation.dart';

import '../core/constants/enums.dart';
import '../data/models/nutrition.dart';
import '../data/repositories/nutrition_repository.dart';
import 'profile_controller.dart';

/// Coach-side authoring of the weekly meal plan. Loads the current plan into an
/// editable per-day / per-slot structure, lets the coach add and remove foods
/// from the library, then saves it back so members pick it up.
class MealPlanBuilderController extends ChangeNotifier {
  MealPlanBuilderController(this._repo);

  final NutritionRepository _repo;

  LoadStatus _status = LoadStatus.idle;
  bool _saving = false;
  List<FoodItem> _library = const [];

  String _planId = 'plan_default';
  String _title = '';
  String _coachName = '';

  int _selectedWeekday = DateTime.now().weekday;

  /// weekday (1–7) → meal slot → ordered foods.
  final Map<int, Map<MealType, List<FoodItem>>> _days = {};

  LoadStatus get status => _status;
  bool get saving => _saving;
  List<FoodItem> get library => _library;
  String get title => _title;
  int get selectedWeekday => _selectedWeekday;

  Future<void> load() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      final plan = await _repo.getMealPlan();
      _library = await _repo.getFoodLibrary();
      _planId = plan.id;
      _title = plan.title;
      _coachName = plan.coachName;
      _days.clear();
      for (final day in plan.days) {
        final slots = <MealType, List<FoodItem>>{};
        for (final meal in day.meals) {
          slots.putIfAbsent(meal.type, () => []).addAll(meal.items);
        }
        _days[day.weekday] = slots;
      }
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

  void setTitle(String value) {
    _title = value;
    // No notify: driven by a TextField that already holds its own text.
  }

  List<FoodItem> foodsFor(int weekday, MealType type) =>
      _days[weekday]?[type] ?? const [];

  int dayKcal(int weekday) {
    final slots = _days[weekday];
    if (slots == null) return 0;
    var total = 0;
    for (final foods in slots.values) {
      for (final f in foods) {
        total += f.kcal;
      }
    }
    return total;
  }

  void addFood(int weekday, MealType type, FoodItem food) {
    _days
        .putIfAbsent(weekday, () => {})
        .putIfAbsent(type, () => [])
        .add(food);
    notifyListeners();
  }

  void removeFoodAt(int weekday, MealType type, int index) {
    final list = _days[weekday]?[type];
    if (list == null || index < 0 || index >= list.length) return;
    list.removeAt(index);
    notifyListeners();
  }

  /// Copy the selected day's slots onto every other weekday.
  void copyDayToAll(int weekday) {
    final source = _days[weekday];
    if (source == null) return;
    for (var wd = 1; wd <= 7; wd++) {
      if (wd == weekday) continue;
      _days[wd] = {
        for (final entry in source.entries)
          entry.key: List<FoodItem>.from(entry.value),
      };
    }
    notifyListeners();
  }

  MealPlan _build() {
    const order = [
      MealType.breakfast,
      MealType.lunch,
      MealType.snack,
      MealType.dinner,
    ];
    final days = <DayMealPlan>[];
    for (var wd = 1; wd <= 7; wd++) {
      final slots = _days[wd] ?? const {};
      final meals = <PlannedMeal>[];
      for (final type in order) {
        final foods = slots[type];
        if (foods == null || foods.isEmpty) continue;
        meals.add(PlannedMeal(
          id: 'm_${wd}_${type.name}',
          type: type,
          title: type.label,
          items: List<FoodItem>.from(foods),
        ));
      }
      days.add(DayMealPlan(weekday: wd, meals: meals));
    }
    return MealPlan(
      id: _planId,
      title: _title.trim().isEmpty ? 'Meal plan' : _title.trim(),
      coachName: _coachName,
      days: days,
    );
  }

  Future<bool> save() async {
    _saving = true;
    notifyListeners();
    try {
      await _repo.saveMealPlan(_build());
      _saving = false;
      notifyListeners();
      return true;
    } catch (_) {
      _saving = false;
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _status = LoadStatus.idle;
    _days.clear();
    _library = const [];
    _selectedWeekday = DateTime.now().weekday;
    notifyListeners();
  }
}
