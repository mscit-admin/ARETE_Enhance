import '../mock/mock_coach.dart';
import '../models/coach_chat.dart';
import 'coach_repository.dart';

class MockCoachRepository implements CoachRepository {
  @override
  Future<List<ChatMessage>> getThread() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockCoach.thread();
  }

  @override
  Future<List<CoachSession>> getSessions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockCoach.sessions();
  }
}
