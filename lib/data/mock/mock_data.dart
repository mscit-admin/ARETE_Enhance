import '../../core/constants/enums.dart';
import '../models/body_metrics.dart';
import '../models/member.dart';
import '../models/membership.dart';
import '../models/trainer.dart';

/// Seed data for the local-first build. Replace with real API data later.
class MockData {
  MockData._();

  static Member member = Member(
    id: 'm_001',
    fullName: 'Yahya Gashott',
    email: 'yahya.gashott@gmail.com',
    phone: '+1 555 0142',
    photoUrl: null,
    gender: Gender.male,
    dateOfBirth: DateTime(1995, 4, 18),
    goal: FitnessGoal.buildMuscle,
    experience: ExperienceLevel.intermediate,
    units: UnitSystem.metric,
    metrics: const BodyMetrics(
      weightKg: 78.4,
      heightCm: 180,
      bodyFatPercent: 18,
      waistCm: 82,
    ),
    membership: Membership(
      tier: MembershipTier.gold,
      status: MembershipStatus.active,
      joinedOn: DateTime(2025, 5, 6),
      renewsOn: DateTime(2026, 5, 6),
    ),
    currentStreakDays: 24,
    weeklyTargetSessions: 4,
    sessionsThisWeek: 3,
    assignedTrainerId: 't_001',
    badges: ['First Workout', '7-Day Streak', '10 PRs', 'Early Bird'],
  );

  static Trainer trainer = const Trainer(
    id: 't_001',
    fullName: 'Sara Kessler',
    email: 'sara.k@arete.fit',
    photoUrl: null,
    certifications: ['NASM-CPT', 'Precision Nutrition L1'],
    specialty: 'Strength & Hypertrophy',
    bio:
        'Strength coach focused on sustainable progressive overload. 8 years '
        'coaching intermediate lifters toward their first real PRs.',
    clientIds: ['m_001', 'm_002', 'm_003', 'm_004'],
    avgResponseHours: 1,
    rating: 4.9,
  );

  /// Extra clients so the trainer roster view has content.
  static List<Member> roster = [
    member,
    Member(
      id: 'm_002',
      fullName: 'Priya Nair',
      email: 'priya@example.com',
      gender: Gender.female,
      dateOfBirth: DateTime(1992, 9, 2),
      goal: FitnessGoal.loseWeight,
      experience: ExperienceLevel.beginner,
      units: UnitSystem.metric,
      metrics: const BodyMetrics(weightKg: 64, heightCm: 165, bodyFatPercent: 28),
      membership: Membership(
        tier: MembershipTier.silver,
        status: MembershipStatus.active,
        joinedOn: DateTime(2025, 11, 1),
        renewsOn: DateTime(2026, 11, 1),
      ),
      currentStreakDays: 5,
      weeklyTargetSessions: 3,
      sessionsThisWeek: 2,
      assignedTrainerId: 't_001',
    ),
    Member(
      id: 'm_003',
      fullName: 'Marcus Lee',
      email: 'marcus@example.com',
      gender: Gender.male,
      dateOfBirth: DateTime(1988, 1, 23),
      goal: FitnessGoal.endurance,
      experience: ExperienceLevel.advanced,
      units: UnitSystem.imperial,
      metrics: const BodyMetrics(weightKg: 82, heightCm: 178, bodyFatPercent: 14),
      membership: Membership(
        tier: MembershipTier.elite,
        status: MembershipStatus.active,
        joinedOn: DateTime(2024, 3, 12),
        renewsOn: DateTime(2026, 3, 12),
      ),
      currentStreakDays: 61,
      weeklyTargetSessions: 5,
      sessionsThisWeek: 4,
      assignedTrainerId: 't_001',
    ),
    Member(
      id: 'm_004',
      fullName: 'Dana Ortiz',
      email: 'dana@example.com',
      gender: Gender.female,
      dateOfBirth: DateTime(1999, 7, 30),
      goal: FitnessGoal.generalFitness,
      experience: ExperienceLevel.intermediate,
      units: UnitSystem.metric,
      metrics: const BodyMetrics(weightKg: 59, heightCm: 170, bodyFatPercent: 22),
      membership: Membership(
        tier: MembershipTier.gold,
        status: MembershipStatus.frozen,
        joinedOn: DateTime(2025, 6, 18),
        renewsOn: DateTime(2026, 6, 18),
      ),
      currentStreakDays: 0,
      weeklyTargetSessions: 3,
      sessionsThisWeek: 0,
      assignedTrainerId: 't_001',
    ),
  ];
}
