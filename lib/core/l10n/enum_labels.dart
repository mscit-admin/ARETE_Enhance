import '../../l10n/app_localizations.dart';
import '../constants/enums.dart';

/// Localized display labels for the domain enums. Kept separate from the raw
/// [enums.dart] `.label` getters (which stay English for logging/fallbacks) so
/// UI code can read a translated string via `value.localized(l)`.
extension FitnessGoalL10n on FitnessGoal {
  String localized(AppLocalizations l) => switch (this) {
        FitnessGoal.loseWeight => l.goalLoseWeight,
        FitnessGoal.buildMuscle => l.goalBuildMuscle,
        FitnessGoal.endurance => l.goalEndurance,
        FitnessGoal.generalFitness => l.goalGeneralFitness,
      };
}

extension ExperienceLevelL10n on ExperienceLevel {
  String localized(AppLocalizations l) => switch (this) {
        ExperienceLevel.beginner => l.expBeginner,
        ExperienceLevel.intermediate => l.expIntermediate,
        ExperienceLevel.advanced => l.expAdvanced,
      };
}

extension MembershipTierL10n on MembershipTier {
  String localized(AppLocalizations l) => switch (this) {
        MembershipTier.basic => l.tierBasic,
        MembershipTier.silver => l.tierSilver,
        MembershipTier.gold => l.tierGold,
        MembershipTier.elite => l.tierElite,
      };
}

extension MembershipStatusL10n on MembershipStatus {
  String localized(AppLocalizations l) => switch (this) {
        MembershipStatus.active => l.statusActive,
        MembershipStatus.expired => l.statusExpired,
        MembershipStatus.frozen => l.statusFrozen,
      };
}

extension UnitSystemL10n on UnitSystem {
  String localized(AppLocalizations l) =>
      this == UnitSystem.metric ? l.unitsMetric : l.unitsImperial;
}

extension EquipmentAccessL10n on EquipmentAccess {
  String localized(AppLocalizations l) => switch (this) {
        EquipmentAccess.bodyweight => l.equipBodyweight,
        EquipmentAccess.dumbbells => l.equipDumbbells,
        EquipmentAccess.fullGym => l.equipFullGym,
        EquipmentAccess.bands => l.equipBands,
      };
}

extension ActivityLevelL10n on ActivityLevel {
  String localized(AppLocalizations l) => switch (this) {
        ActivityLevel.sedentary => l.activitySedentary,
        ActivityLevel.light => l.activityLight,
        ActivityLevel.moderate => l.activityModerate,
        ActivityLevel.high => l.activityHigh,
      };
}

extension GenderL10n on Gender {
  String localized(AppLocalizations l) => switch (this) {
        Gender.male => l.genderMale,
        Gender.female => l.genderFemale,
        Gender.other => l.genderOther,
        Gender.preferNotToSay => l.genderPreferNot,
      };
}
