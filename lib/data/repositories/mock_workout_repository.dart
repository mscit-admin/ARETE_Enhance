import '../mock/mock_workouts.dart';
import '../models/workout_session.dart';
import 'workout_repository.dart';

class MockWorkoutRepository implements WorkoutRepository {
  static const _latency = Duration(milliseconds: 300);

  @override
  Future<WorkoutSession> getTodayWorkout() async {
    await Future.delayed(_latency);
    return MockWorkouts.todaySession();
  }

  @override
  Future<void> saveSession(WorkoutSession session) async {
    await Future.delayed(_latency);
    // In-memory build: nothing to persist yet.
  }
}
