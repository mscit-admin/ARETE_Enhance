import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../mock/mock_data.dart';
import '../models/member.dart';
import '../models/trainer.dart';
import 'profile_repository.dart';

/// Profile persistence backed by on-device storage. The member is seeded from
/// mock data on first run, then any edits (details, units, water intake) are
/// saved as JSON and survive app restarts. Trainer/roster data stays mocked.
class LocalProfileRepository implements ProfileRepository {
  static const _memberKey = 'profile_member_v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<Member> getCurrentMember() async {
    final p = await _prefs;
    final raw = p.getString(_memberKey);
    if (raw != null) {
      try {
        return Member.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Corrupt/old shape — fall through to a fresh seed.
      }
    }
    final seeded = MockData.member;
    await p.setString(_memberKey, jsonEncode(seeded.toJson()));
    return seeded;
  }

  @override
  Future<Member> updateMember(Member member) async {
    final p = await _prefs;
    await p.setString(_memberKey, jsonEncode(member.toJson()));
    return member;
  }

  @override
  Future<Trainer?> getAssignedTrainer(String memberId) async {
    return MockData.trainer;
  }

  @override
  Future<List<Member>> getClientsForTrainer(String trainerId) async {
    return MockData.roster
        .where((m) => m.assignedTrainerId == trainerId)
        .toList();
  }

  @override
  Future<Trainer> getTrainerProfile() async => MockData.trainer;
}
