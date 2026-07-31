import '../models/member.dart';
import '../models/trainer.dart';

/// Abstraction over profile data. The UI depends only on this interface, so
/// the local mock can be swapped for an API/Firebase implementation later
/// without touching any screen.
abstract class ProfileRepository {
  Future<Member> getCurrentMember();

  Future<Member> updateMember(Member member);

  /// The trainer assigned to the given member, if any.
  Future<Trainer?> getAssignedTrainer(String memberId);

  /// Roster of members coached by the given trainer (trainer role view).
  Future<List<Member>> getClientsForTrainer(String trainerId);

  Future<Trainer> getTrainerProfile();
}
