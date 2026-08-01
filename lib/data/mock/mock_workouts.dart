import '../models/exercise.dart';
import '../models/workout_session.dart';

/// Seed data for today's workout in the local-first build.
class MockWorkouts {
  MockWorkouts._();

  static const List<Exercise> _pushDayA = [
    Exercise(
      id: 'ex_bench',
      name: 'Barbell Bench Press',
      muscleGroup: 'Chest',
      equipment: 'Barbell',
      targetSets: 4,
      targetReps: 10,
      restSeconds: 90,
      suggestedWeightKg: 60,
      previousBest1RM: 78,
      lastWeightKg: 57.5,
      lastReps: 10,
      cues: [
        'Retract shoulder blades',
        'Bar to mid-chest',
        'Drive through the floor',
      ],
    ),
    Exercise(
      id: 'ex_incline_db',
      name: 'Incline Dumbbell Press',
      muscleGroup: 'Upper chest',
      equipment: 'Dumbbells',
      targetSets: 3,
      targetReps: 12,
      restSeconds: 75,
      suggestedWeightKg: 24,
      previousBest1RM: 34,
      lastWeightKg: 22,
      lastReps: 12,
      cues: ['30° bench', 'Control the descent'],
    ),
    Exercise(
      id: 'ex_ohp',
      name: 'Overhead Press',
      muscleGroup: 'Shoulders',
      equipment: 'Barbell',
      targetSets: 3,
      targetReps: 8,
      restSeconds: 90,
      suggestedWeightKg: 40,
      previousBest1RM: 52,
      lastWeightKg: 40,
      lastReps: 8,
      cues: ['Squeeze glutes', 'Bar over mid-foot'],
    ),
    Exercise(
      id: 'ex_lateral',
      name: 'Lateral Raise',
      muscleGroup: 'Side delts',
      equipment: 'Dumbbells',
      targetSets: 3,
      targetReps: 15,
      restSeconds: 45,
      suggestedWeightKg: 10,
      previousBest1RM: 13,
      lastWeightKg: 9,
      lastReps: 15,
      cues: ['Lead with elbows', 'No swinging'],
    ),
    Exercise(
      id: 'ex_pushdown',
      name: 'Triceps Pushdown',
      muscleGroup: 'Triceps',
      equipment: 'Cable',
      targetSets: 3,
      targetReps: 12,
      restSeconds: 45,
      suggestedWeightKg: 25,
      previousBest1RM: 32,
      lastWeightKg: 25,
      lastReps: 12,
      cues: ['Elbows pinned', 'Full lockout'],
    ),
    Exercise(
      id: 'ex_cable_fly',
      name: 'Cable Fly',
      muscleGroup: 'Chest',
      equipment: 'Cable',
      targetSets: 3,
      targetReps: 15,
      restSeconds: 45,
      suggestedWeightKg: 15,
      previousBest1RM: 20,
      lastWeightKg: 14,
      lastReps: 15,
      cues: ['Slight forward lean', 'Squeeze at the middle'],
    ),
  ];

  /// A fresh session (empty logs) so each start begins clean.
  static WorkoutSession todaySession() => WorkoutSession(
        id: 'w_push_a',
        title: 'Push Day · A',
        subtitle: 'Chest · Shoulders · Triceps',
        exercises: [
          for (final e in _pushDayA) WorkoutExercise(exercise: e),
        ],
      );
}
