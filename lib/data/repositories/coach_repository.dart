import '../models/coach_chat.dart';

/// Abstraction over the member ↔ coach messaging and sessions.
abstract class CoachRepository {
  Future<List<ChatMessage>> getThread();
  Future<List<CoachSession>> getSessions();
}
