import '../models/workout_session.dart';

/// Abstraction over workout data. UI depends only on this, so the local mock
/// can be swapped for an API implementation later with no screen changes.
abstract class WorkoutRepository {
  /// The member's scheduled session for today (fresh, unlogged).
  Future<WorkoutSession> getTodayWorkout();

  /// Persist a completed session (no-op in the mock for now).
  Future<void> saveSession(WorkoutSession session);
}
