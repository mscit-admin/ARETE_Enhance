import '../mock/mock_data.dart';
import '../models/member.dart';
import '../models/trainer.dart';
import 'profile_repository.dart';

/// In-memory implementation used for the local-first build. Mutations persist
/// only for the app session. Simulated latency makes loading states realistic.
class MockProfileRepository implements ProfileRepository {
  Member _member = MockData.member;

  static const _latency = Duration(milliseconds: 350);

  @override
  Future<Member> getCurrentMember() async {
    await Future.delayed(_latency);
    return _member;
  }

  @override
  Future<Member> updateMember(Member member) async {
    await Future.delayed(_latency);
    _member = member;
    return _member;
  }

  @override
  Future<Trainer?> getAssignedTrainer(String memberId) async {
    await Future.delayed(_latency);
    if (_member.assignedTrainerId == null) return null;
    return MockData.trainer;
  }

  @override
  Future<List<Member>> getClientsForTrainer(String trainerId) async {
    await Future.delayed(_latency);
    return MockData.roster
        .where((m) => m.assignedTrainerId == trainerId)
        .toList();
  }

  @override
  Future<Trainer> getTrainerProfile() async {
    await Future.delayed(_latency);
    return MockData.trainer;
  }
}
