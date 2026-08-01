import '../../core/constants/enums.dart';

/// A pre-built training program the assessment can recommend.
class StarterPlan {
  const StarterPlan({
    required this.id,
    required this.name,
    required this.split,
    required this.daysPerWeek,
    required this.weeks,
    required this.goals,
    required this.experience,
    required this.equipment,
    required this.avgMinutes,
    required this.description,
  });

  final String id;
  final String name;
  final String split;
  final int daysPerWeek;
  final int weeks;

  /// Goals this plan serves well.
  final List<FitnessGoal> goals;

  /// Experience levels this plan suits.
  final List<ExperienceLevel> experience;

  /// Minimum equipment this plan needs.
  final List<EquipmentAccess> equipment;

  final int avgMinutes;
  final String description;
}
