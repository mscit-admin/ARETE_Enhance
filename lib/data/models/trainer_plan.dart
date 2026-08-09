/// One exercise line inside a trainer-authored plan. Carries the coaching
/// parameters (sets/reps/suggested weight/rest/notes) and the day it belongs
/// to. Extra fields are additive so older payloads still parse.
class PlanExercise {
  const PlanExercise({
    required this.name,
    this.exerciseId,
    this.nameAr = '',
    this.muscleGroup = '',
    this.day = 0,
    this.sets = 3,
    this.reps = 10,
    this.weight,
    this.rest,
    this.notes = '',
  });

  final String name;
  final String? exerciseId;
  final String nameAr;
  final String muscleGroup;
  final int day;
  final int sets;
  final int reps;
  final double? weight;
  final int? rest;
  final String notes;

  /// Best display name for the given text direction.
  String label(bool arabic) => (arabic && nameAr.isNotEmpty) ? nameAr : name;

  factory PlanExercise.fromJson(Map<String, dynamic> j) => PlanExercise(
        name: j['name'] as String? ?? '',
        exerciseId: j['exerciseId'] as String?,
        nameAr: j['nameAr'] as String? ?? '',
        muscleGroup: j['muscleGroup'] as String? ?? '',
        day: (j['day'] as num?)?.toInt() ?? 0,
        sets: (j['sets'] as num?)?.toInt() ?? 3,
        reps: (j['reps'] as num?)?.toInt() ?? 10,
        weight: (j['weight'] as num?)?.toDouble(),
        rest: (j['rest'] as num?)?.toInt(),
        notes: j['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (exerciseId != null) 'exerciseId': exerciseId,
        'day': day,
        'sets': sets,
        'reps': reps,
        if (weight != null) 'weight': weight,
        if (rest != null) 'rest': rest,
        if (notes.isNotEmpty) 'notes': notes,
      };
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
