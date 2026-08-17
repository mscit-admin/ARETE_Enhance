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
    this.planStartDay = '',
    this.planDurationDays = 0,
    this.weeklyMeals = false,
  });

  static const int defaultTargetGlasses = 8;
  static const int defaultGlassMl = 250;

  /// Bounds the UI (and the server) enforce.
  static const int minTargetGlasses = 1;
  static const int maxTargetGlasses = 30;
  static const List<int> glassSizes = [200, 250, 330, 500];

  /// How long a plan can be asked to run for. 0 means "no end date".
  static const int ongoing = 0;
  static const List<int> planDurations = [7, 14, 30, ongoing];

  /// How many meals a day the schedule generator will produce.
  static const int minMealsPerDay = 2;
  static const int maxMealsPerDay = 8;

  final int waterTargetGlasses;
  final int glassMl;
  final List<MealSlot>? mealSchedule;

  /// `yyyy-MM-dd` the plan started on; empty when none was set.
  final String planStartDay;

  /// 7, 14, 30 — or [ongoing] for a plan that never expires.
  final int planDurationDays;

  /// False: one set of meals repeated every day. True: the meals differ by
  /// weekday and the week repeats.
  final bool weeklyMeals;

  /// The daily goal in litres, for display next to the glass count.
  double get targetLitres => waterTargetGlasses * glassMl / 1000;

  DateTime? get planStart => planStartDay.isEmpty
      ? null
      : DateTime.tryParse(planStartDay);

  /// The last day the plan covers (inclusive), or null when it never ends.
  DateTime? get planEnd {
    final start = planStart;
    if (start == null || planDurationDays <= 0) return null;
    return DateTime(start.year, start.month, start.day + planDurationDays - 1);
  }

  /// True while the plan still covers [today] — a plan with no end date always
  /// does, and so does a schedule that was never given a period.
  bool isPlanActive([DateTime? today]) {
    final end = planEnd;
    if (end == null) return true;
    final now = today ?? DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    return !day.isAfter(end);
  }

  /// Days remaining including today; 0 once it has run out, null when the plan
  /// has no end date.
  int? daysLeft([DateTime? today]) {
    final end = planEnd;
    if (end == null) return null;
    final now = today ?? DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final left = end.difference(day).inDays + 1;
    return left < 0 ? 0 : left;
  }

  NutritionSettings copyWith({
    int? waterTargetGlasses,
    int? glassMl,
    List<MealSlot>? mealSchedule,
    String? planStartDay,
    int? planDurationDays,
    bool? weeklyMeals,
  }) =>
      NutritionSettings(
        waterTargetGlasses: waterTargetGlasses ?? this.waterTargetGlasses,
        glassMl: glassMl ?? this.glassMl,
        mealSchedule: mealSchedule ?? this.mealSchedule,
        planStartDay: planStartDay ?? this.planStartDay,
        planDurationDays: planDurationDays ?? this.planDurationDays,
        weeklyMeals: weeklyMeals ?? this.weeklyMeals,
      );

  Map<String, dynamic> toJson() => {
        'waterTargetGlasses': waterTargetGlasses,
        'glassMl': glassMl,
        'planStartDay': planStartDay,
        'planDurationDays': planDurationDays,
        'weeklyMeals': weeklyMeals,
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
      weeklyMeals: j['weeklyMeals'] as bool? ?? false,
      planStartDay: _dayOnly(j['planStartDay']),
      planDurationDays:
          _clamp((j['planDurationDays'] as num?)?.toInt() ?? ongoing, 0, 366),
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

  /// Accepts both `yyyy-MM-dd` and a full timestamp (Postgres `date` columns
  /// come back as one through JSON).
  static String _dayOnly(Object? raw) {
    final text = (raw ?? '').toString();
    if (text.length < 10) return '';
    final day = text.substring(0, 10);
    return DateTime.tryParse(day) == null ? '' : day;
  }
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

/// A nutrition plan a coach sent to one of their trainees.
///
/// The app applies it to the member's own schedule and remembers the id it has
/// applied, so a plan lands once and the member stays free to adjust it after.
class CoachNutritionPlan {
  const CoachNutritionPlan({
    required this.id,
    required this.mealSchedule,
    this.waterTargetGlasses,
    this.durationDays = 0,
    this.note = '',
    this.coachName = '',
    this.createdAt,
  });

  final String id;
  final List<MealSlot> mealSchedule;

  /// Null when the coach left the water goal to the member.
  final int? waterTargetGlasses;

  /// How long the coach means the plan to run, in days (0 = no end date).
  final int durationDays;
  final String note;
  final String coachName;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mealSchedule': [for (final s in mealSchedule) s.toJson()],
        'waterTargetGlasses': waterTargetGlasses,
        'durationDays': durationDays,
        'note': note,
        'coachName': coachName,
        'createdAt': createdAt?.toIso8601String(),
      };

  /// Slots always come back marked [MealSource.coach], whatever the payload
  /// says, so the app can tell a coach's meal from one the member added.
  factory CoachNutritionPlan.fromJson(Map<String, dynamic> j) =>
      CoachNutritionPlan(
        id: (j['id'] ?? '').toString(),
        mealSchedule: [
          for (final e in (j['mealSchedule'] as List?) ?? const [])
            if (e is Map)
              MealSlot.fromJson(e.cast<String, dynamic>())
                  .copyWith(source: MealSource.coach),
        ],
        waterTargetGlasses: (j['waterTargetGlasses'] as num?)?.toInt(),
        durationDays: (j['durationDays'] as num?)?.toInt() ?? 0,
        note: (j['note'] ?? '').toString(),
        coachName: (j['coachName'] ?? '').toString(),
        createdAt: j['createdAt'] == null
            ? null
            : DateTime.tryParse(j['createdAt'].toString()),
      );
}

/// What the nutrition endpoint returns: the settings, one day of intake, and
/// the coach's plan when there is one.
class NutritionSnapshot {
  const NutritionSnapshot({
    required this.settings,
    required this.today,
    this.coachPlan,
  });

  final NutritionSettings settings;
  final NutritionDay today;
  final CoachNutritionPlan? coachPlan;
}
