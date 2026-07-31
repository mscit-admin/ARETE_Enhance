import '../../core/constants/enums.dart';
import 'body_metrics.dart';
import 'daily_stats.dart';
import 'membership.dart';

/// The full member profile aggregate.
class Member {
  const Member({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.photoUrl,
    required this.gender,
    required this.dateOfBirth,
    required this.goal,
    required this.experience,
    required this.units,
    required this.metrics,
    required this.dailyStats,
    required this.membership,
    required this.currentStreakDays,
    required this.weeklyTargetSessions,
    required this.sessionsThisWeek,
    this.assignedTrainerId,
    this.badges = const [],
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? photoUrl;
  final Gender gender;
  final DateTime dateOfBirth;
  final FitnessGoal goal;
  final ExperienceLevel experience;
  final UnitSystem units;
  final BodyMetrics metrics;
  final DailyStats dailyStats;
  final Membership membership;
  final int currentStreakDays;
  final int weeklyTargetSessions;
  final int sessionsThisWeek;
  final String? assignedTrainerId;
  final List<String> badges;

  int get ageYears {
    final now = DateTime.now();
    var age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  double get weeklyProgress =>
      weeklyTargetSessions == 0 ? 0 : sessionsThisWeek / weeklyTargetSessions;

  double get genderBmrOffset => switch (gender) {
        Gender.male => 5,
        Gender.female => -161,
        _ => -78, // neutral midpoint when unspecified
      };

  /// Display weight in the member's chosen unit system.
  double get displayWeight => units == UnitSystem.metric
      ? metrics.weightKg
      : metrics.weightKg * 2.2046226218;

  Member copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? photoUrl,
    Gender? gender,
    DateTime? dateOfBirth,
    FitnessGoal? goal,
    ExperienceLevel? experience,
    UnitSystem? units,
    BodyMetrics? metrics,
    DailyStats? dailyStats,
    Membership? membership,
    int? currentStreakDays,
    int? weeklyTargetSessions,
    int? sessionsThisWeek,
    String? assignedTrainerId,
    List<String>? badges,
  }) {
    return Member(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
      units: units ?? this.units,
      metrics: metrics ?? this.metrics,
      dailyStats: dailyStats ?? this.dailyStats,
      membership: membership ?? this.membership,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      weeklyTargetSessions: weeklyTargetSessions ?? this.weeklyTargetSessions,
      sessionsThisWeek: sessionsThisWeek ?? this.sessionsThisWeek,
      assignedTrainerId: assignedTrainerId ?? this.assignedTrainerId,
      badges: badges ?? this.badges,
    );
  }
}
