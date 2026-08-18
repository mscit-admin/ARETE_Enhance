import '../../core/constants/enums.dart';

/// A single food/drink item from the library, with its macros for one serving.
/// Calories are stored as whole kcal; macros as whole grams.
class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.serving,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final String id;
  final String name;

  /// Human-readable serving size, e.g. "1 cup", "150 g", "1 glass".
  final String serving;
  final int kcal;
  final int proteinG;
  final int carbsG;
  final int fatG;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'serving': serving,
        'kcal': kcal,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id'] as String,
        name: json['name'] as String,
        serving: json['serving'] as String? ?? '',
        kcal: json['kcal'] as int? ?? 0,
        proteinG: json['proteinG'] as int? ?? 0,
        carbsG: json['carbsG'] as int? ?? 0,
        fatG: json['fatG'] as int? ?? 0,
      );
}

/// A meal the coach planned for a given day + slot. It groups one or more food
/// items and carries an optional coaching note.
class PlannedMeal {
  const PlannedMeal({
    required this.id,
    required this.type,
    required this.title,
    required this.items,
    this.note,
  });

  final String id;
  final MealType type;
  final String title;
  final List<FoodItem> items;
  final String? note;

  int get kcal => items.fold(0, (sum, f) => sum + f.kcal);
  int get proteinG => items.fold(0, (sum, f) => sum + f.proteinG);
  int get carbsG => items.fold(0, (sum, f) => sum + f.carbsG);
  int get fatG => items.fold(0, (sum, f) => sum + f.fatG);
}

/// The coach's plan for one weekday (1 = Monday … 7 = Sunday, matching
/// [DateTime.weekday]).
class DayMealPlan {
  const DayMealPlan({required this.weekday, required this.meals});

  final int weekday;
  final List<PlannedMeal> meals;

  List<PlannedMeal> mealsOfType(MealType type) =>
      meals.where((m) => m.type == type).toList();

  int get targetKcal => meals.fold(0, (sum, m) => sum + m.kcal);
}

/// A full weekly nutrition plan assigned to the member by their coach.
class MealPlan {
  const MealPlan({
    required this.id,
    required this.title,
    required this.coachName,
    required this.days,
  });

  final String id;
  final String title;
  final String coachName;
  final List<DayMealPlan> days;

  DayMealPlan? dayFor(int weekday) {
    for (final d in days) {
      if (d.weekday == weekday) return d;
    }
    return null;
  }
}

/// A meal the member logged themselves (picked from the library or typed in),
/// as opposed to one planned by the coach.
class LoggedMeal {
  const LoggedMeal({
    required this.id,
    required this.type,
    required this.name,
    required this.kcal,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });

  final String id;
  final MealType type;
  final String name;
  final int kcal;
  final int proteinG;
  final int carbsG;
  final int fatG;

  factory LoggedMeal.fromFood(MealType type, FoodItem food, String id) =>
      LoggedMeal(
        id: id,
        type: type,
        name: food.name,
        kcal: food.kcal,
        proteinG: food.proteinG,
        carbsG: food.carbsG,
        fatG: food.fatG,
      );
}
