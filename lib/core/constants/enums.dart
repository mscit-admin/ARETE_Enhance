/// Domain enums shared across modules.

enum UserRole { member, trainer }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.member => 'Member',
        UserRole.trainer => 'Trainer',
      };
}

enum FitnessGoal { loseWeight, buildMuscle, endurance, generalFitness }

extension FitnessGoalX on FitnessGoal {
  String get label => switch (this) {
        FitnessGoal.loseWeight => 'Lose Weight',
        FitnessGoal.buildMuscle => 'Build Muscle',
        FitnessGoal.endurance => 'Endurance',
        FitnessGoal.generalFitness => 'General Fitness',
      };
}

enum ExperienceLevel { beginner, intermediate, advanced }

extension ExperienceLevelX on ExperienceLevel {
  String get label => switch (this) {
        ExperienceLevel.beginner => 'Beginner',
        ExperienceLevel.intermediate => 'Intermediate',
        ExperienceLevel.advanced => 'Advanced',
      };
}

enum MembershipTier { basic, silver, gold, elite }

extension MembershipTierX on MembershipTier {
  String get label => switch (this) {
        MembershipTier.basic => 'Basic',
        MembershipTier.silver => 'Silver',
        MembershipTier.gold => 'Gold',
        MembershipTier.elite => 'Elite',
      };
}

enum MembershipStatus { active, expired, frozen }

extension MembershipStatusX on MembershipStatus {
  String get label => switch (this) {
        MembershipStatus.active => 'Active',
        MembershipStatus.expired => 'Expired',
        MembershipStatus.frozen => 'Frozen',
      };
}

enum UnitSystem { metric, imperial }

extension UnitSystemX on UnitSystem {
  String get weightUnit => this == UnitSystem.metric ? 'kg' : 'lb';
  String get heightUnit => this == UnitSystem.metric ? 'cm' : 'in';
  String get label => this == UnitSystem.metric ? 'Metric (kg, cm)' : 'Imperial (lb, in)';
}

enum EquipmentAccess { bodyweight, dumbbells, fullGym, bands }

extension EquipmentAccessX on EquipmentAccess {
  String get label => switch (this) {
        EquipmentAccess.bodyweight => 'Bodyweight only',
        EquipmentAccess.dumbbells => 'Dumbbells',
        EquipmentAccess.fullGym => 'Full gym',
        EquipmentAccess.bands => 'Resistance bands',
      };
}

enum ActivityLevel { sedentary, light, moderate, high }

extension ActivityLevelX on ActivityLevel {
  String get label => switch (this) {
        ActivityLevel.sedentary => 'Sedentary (desk job)',
        ActivityLevel.light => 'Lightly active',
        ActivityLevel.moderate => 'Moderately active',
        ActivityLevel.high => 'Very active',
      };

  /// TDEE multiplier applied to BMR.
  double get factor => switch (this) {
        ActivityLevel.sedentary => 1.2,
        ActivityLevel.light => 1.375,
        ActivityLevel.moderate => 1.55,
        ActivityLevel.high => 1.725,
      };
}

/// The meal slots a day's nutrition plan is broken into.
enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeX on MealType {
  String get label => switch (this) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.dinner => 'Dinner',
        MealType.snack => 'Snack',
      };

  /// Stable key used in JSON / logging.
  String get key => name;

  static MealType fromKey(String key) =>
      MealType.values.firstWhere((t) => t.name == key,
          orElse: () => MealType.snack);
}

enum Gender { male, female, other, preferNotToSay }

extension GenderX on Gender {
  String get label => switch (this) {
        Gender.male => 'Male',
        Gender.female => 'Female',
        Gender.other => 'Other',
        Gender.preferNotToSay => 'Prefer not to say',
      };
}
