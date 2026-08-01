import '../api/api_client.dart';
import '../mock/mock_data.dart';
import '../models/member.dart';
import '../models/trainer.dart';
import 'profile_repository.dart';

/// Profile backed by the ARETE server (`/api/app/profile`).
///
/// Note: daily stats (water/steps/…) are not yet stored server-side, so on
/// [updateMember] we keep the client's `dailyStats` rather than letting the
/// server response reset them. Trainer/roster data stays mocked until the
/// trainer endpoints exist.
class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._client);

  final ApiClient _client;

  @override
  Future<Member> getCurrentMember() async {
    final json = await _client.get('/api/app/profile') as Map<String, dynamic>;
    return Member.fromJson(json);
  }

  @override
  Future<Member> updateMember(Member member) async {
    final body = {
      'fullName': member.fullName,
      'phone': member.phone,
      'gender': member.gender.name,
      'dateOfBirth': member.dateOfBirth.toIso8601String(),
      'goal': member.goal.name,
      'experience': member.experience.name,
      'units': member.units.name,
      'weightKg': member.metrics.weightKg,
      'heightCm': member.metrics.heightCm,
    };
    final json =
        await _client.put('/api/app/profile', body) as Map<String, dynamic>;
    final server = Member.fromJson(json);
    // Preserve client-only daily stats (server doesn't own them yet).
    return server.copyWith(dailyStats: member.dailyStats);
  }

  // ---- Trainer features remain local until server endpoints exist ----
  @override
  Future<Trainer?> getAssignedTrainer(String memberId) async =>
      MockData.trainer;

  @override
  Future<List<Member>> getClientsForTrainer(String trainerId) async =>
      MockData.roster;

  @override
  Future<Trainer> getTrainerProfile() async => MockData.trainer;
}
