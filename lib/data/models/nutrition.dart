import 'meal_slot.dart';

/// The member's nutrition settings: how much water they aim for, the size of a
/// glass, and the meal schedule the reminders are built from.
///
/// A null [mealSchedule] means "no schedule stored yet" — the app falls back to
/// [MealSlot.defaults].
class NutritionSettings {
  const NutritionSettings({
    this.waterTargetGlasses = defaultTargetGlasses,
    this.glassMl = defaultGlassMl,
    this.mealSchedule,
  });

  static const int defaultTargetGlasses = 8;
  static const int defaultGlassMl = 250;

  /// Bounds the UI (and the server) enforce.
  static const int minTargetGlasses = 1;
  static const int maxTargetGlasses = 30;
  static const List<int> glassSizes = [200, 250, 330, 500];

  final int waterTargetGlasses;
  final int glassMl;
  final List<MealSlot>? mealSchedule;

  /// The daily goal in litres, for display next to the glass count.
  double get targetLitres => waterTargetGlasses * glassMl / 1000;

  NutritionSettings copyWith({
    int? waterTargetGlasses,
    int? glassMl,
    List<MealSlot>? mealSchedule,
  }) =>
      NutritionSettings(
        waterTargetGlasses: waterTargetGlasses ?? this.waterTargetGlasses,
        glassMl: glassMl ?? this.glassMl,
        mealSchedule: mealSchedule ?? this.mealSchedule,
      );

  Map<String, dynamic> toJson() => {
        'waterTargetGlasses': waterTargetGlasses,
        'glassMl': glassMl,
        if (mealSchedule != null)
          'mealSchedule': [for (final s in mealSchedule!) s.toJson()],
      };

  factory NutritionSettings.fromJson(Map<String, dynamic> j) {
    final raw = j['mealSchedule'];
    return NutritionSettings(
      waterTargetGlasses: _clamp(
        (j['waterTargetGlasses'] as num?)?.toInt() ?? defaultTargetGlasses,
        minTargetGlasses,
        maxTargetGlasses,
      ),
      glassMl: _clamp((j['glassMl'] as num?)?.toInt() ?? defaultGlassMl, 50, 2000),
      mealSchedule: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => MealSlot.fromJson(e.cast<String, dynamic>()))
              .where((s) => s.id.isNotEmpty)
              .toList()
          : null,
    );
  }

  static int _clamp(int v, int min, int max) => v < min ? min : (v > max ? max : v);
}

/// One day of intake: glasses drunk and which meals were ticked off.
class NutritionDay {
  const NutritionDay({
    required this.day,
    this.waterGlasses = 0,
    this.mealsDone = const {},
  });

  /// `yyyy-MM-dd` in the member's local time.
  final String day;
  final int waterGlasses;
  final Set<String> mealsDone;

  static String keyFor(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  bool isDone(String mealId) => mealsDone.contains(mealId);

  NutritionDay copyWith({int? waterGlasses, Set<String>? mealsDone}) =>
      NutritionDay(
        day: day,
        waterGlasses: waterGlasses ?? this.waterGlasses,
        mealsDone: mealsDone ?? this.mealsDone,
      );

  Map<String, dynamic> toJson() => {
        'day': day,
        'waterGlasses': waterGlasses,
        'mealsDone': mealsDone.toList(),
      };

  factory NutritionDay.fromJson(Map<String, dynamic> j) => NutritionDay(
        day: (j['day'] ?? '').toString(),
        waterGlasses: ((j['waterGlasses'] as num?)?.toInt() ?? 0).clamp(0, 60),
        mealsDone: {
          for (final id in (j['mealsDone'] as List?) ?? const []) id.toString(),
        },
      );
}

/// What the nutrition endpoint returns: the settings plus one day of intake.
class NutritionSnapshot {
  const NutritionSnapshot({required this.settings, required this.today});

  final NutritionSettings settings;
  final NutritionDay today;
}
