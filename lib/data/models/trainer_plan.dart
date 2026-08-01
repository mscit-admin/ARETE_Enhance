/// One exercise line inside a trainer-authored plan.
class PlanExercise {
  const PlanExercise({required this.name, this.sets = 3, this.reps = 10});

  final String name;
  final int sets;
  final int reps;

  factory PlanExercise.fromJson(Map<String, dynamic> j) => PlanExercise(
        name: j['name'] as String? ?? '',
        sets: (j['sets'] as num?)?.toInt() ?? 3,
        reps: (j['reps'] as num?)?.toInt() ?? 10,
      );

  Map<String, dynamic> toJson() => {'name': name, 'sets': sets, 'reps': reps};
}

/// A workout plan a trainer builds and assigns to clients. Used both as a
/// summary row (list view — [exerciseCount]/[assignedCount] filled) and as a
/// full detail object (with [exercises]).
class TrainerPlan {
  const TrainerPlan({
    required this.id,
    required this.name,
    this.description = '',
    this.daysPerWeek = 3,
    this.weeks = 8,
    this.exercises = const [],
    this.exerciseCount,
    this.assignedCount,
    this.coachName,
  });

  final String id;
  final String name;
  final String description;
  final int daysPerWeek;
  final int weeks;
  final List<PlanExercise> exercises;

  /// Summary counts (present on the trainer's list rows).
  final int? exerciseCount;
  final int? assignedCount;

  /// The coach who assigned this plan (present on a trainee's assigned plan).
  final String? coachName;

  int get exCount => exerciseCount ?? exercises.length;

  factory TrainerPlan.fromJson(Map<String, dynamic> j) => TrainerPlan(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        daysPerWeek: (j['daysPerWeek'] as num?)?.toInt() ?? 3,
        weeks: (j['weeks'] as num?)?.toInt() ?? 8,
        exercises: (j['exercises'] as List?)
                ?.map((e) => PlanExercise.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        exerciseCount: (j['exerciseCount'] as num?)?.toInt(),
        assignedCount: (j['assignedCount'] as num?)?.toInt(),
        coachName: j['coachName'] as String?,
      );
}
