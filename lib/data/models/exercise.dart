/// A single exercise definition within a workout.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.targetSets,
    required this.targetReps,
    required this.restSeconds,
    required this.suggestedWeightKg,
    this.previousBest1RM,
    this.lastWeightKg,
    this.lastReps,
    this.cues = const [],
  });

  final String id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final int targetSets;
  final int targetReps;
  final int restSeconds;
  final double suggestedWeightKg;

  /// Best estimated 1-rep-max seen before this session (for PR detection).
  final double? previousBest1RM;

  /// What the member did last time, for the "vs last" comparison.
  final double? lastWeightKg;
  final int? lastReps;

  final List<String> cues;
}
