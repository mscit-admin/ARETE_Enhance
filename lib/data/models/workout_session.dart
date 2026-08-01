import 'exercise.dart';
import 'set_log.dart';

/// An exercise within a session plus the sets logged against it.
class WorkoutExercise {
  WorkoutExercise({required this.exercise, List<SetLog>? loggedSets})
      : loggedSets = loggedSets ?? [];

  final Exercise exercise;
  final List<SetLog> loggedSets;

  bool get isComplete => loggedSets.length >= exercise.targetSets;
  int get remainingSets =>
      (exercise.targetSets - loggedSets.length).clamp(0, exercise.targetSets);

  double get volume =>
      loggedSets.fold(0.0, (sum, s) => sum + s.volume);
}

/// A full training session (today's workout).
class WorkoutSession {
  WorkoutSession({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.exercises,
    this.startedAt,
    this.finishedAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<WorkoutExercise> exercises;
  DateTime? startedAt;
  DateTime? finishedAt;

  int get totalTargetSets =>
      exercises.fold(0, (sum, e) => sum + e.exercise.targetSets);

  int get completedSets =>
      exercises.fold(0, (sum, e) => sum + e.loggedSets.length);

  double get totalVolume =>
      exercises.fold(0.0, (sum, e) => sum + e.volume);

  int get prCount => exercises.fold(
      0, (sum, e) => sum + e.loggedSets.where((s) => s.isPr).length);

  double get progress =>
      totalTargetSets == 0 ? 0 : completedSets / totalTargetSets;
}
