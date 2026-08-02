import '../../core/constants/enums.dart';
import '../models/starter_plan.dart';

/// The starter-plan library the assessment matches against.
class MockPlans {
  MockPlans._();

  /// Look a plan up by its id (used to restore the persisted selection).
  static StarterPlan? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  static const List<StarterPlan> all = [
    StarterPlan(
      id: 'plan_foundation3',
      name: 'Foundation 3-Day Full Body',
      split: 'Full body',
      daysPerWeek: 3,
      weeks: 8,
      goals: [FitnessGoal.generalFitness, FitnessGoal.buildMuscle],
      experience: [ExperienceLevel.beginner],
      equipment: [EquipmentAccess.dumbbells, EquipmentAccess.fullGym],
      avgMinutes: 45,
      description:
          'Three balanced full-body sessions a week to build a strength base '
          'and groove the main movement patterns.',
    ),
    StarterPlan(
      id: 'plan_upperlower4',
      name: 'Upper / Lower 4-Day',
      split: 'Upper / Lower',
      daysPerWeek: 4,
      weeks: 8,
      goals: [FitnessGoal.buildMuscle, FitnessGoal.generalFitness],
      experience: [ExperienceLevel.intermediate, ExperienceLevel.advanced],
      equipment: [EquipmentAccess.fullGym],
      avgMinutes: 55,
      description:
          'Four sessions split into two upper and two lower days, with enough '
          'volume to drive muscle growth while recovering between sessions.',
    ),
    StarterPlan(
      id: 'plan_ppl6',
      name: 'Push / Pull / Legs 6-Day',
      split: 'Push / Pull / Legs',
      daysPerWeek: 6,
      weeks: 10,
      goals: [FitnessGoal.buildMuscle],
      experience: [ExperienceLevel.advanced],
      equipment: [EquipmentAccess.fullGym],
      avgMinutes: 60,
      description:
          'High-frequency hypertrophy split for experienced lifters who can '
          'train six days a week.',
    ),
    StarterPlan(
      id: 'plan_fatloss4',
      name: 'Fat-Loss Circuit 4-Day',
      split: 'Full-body circuits',
      daysPerWeek: 4,
      weeks: 6,
      goals: [FitnessGoal.loseWeight, FitnessGoal.generalFitness],
      experience: [ExperienceLevel.beginner, ExperienceLevel.intermediate],
      equipment: [EquipmentAccess.dumbbells, EquipmentAccess.bands],
      avgMinutes: 40,
      description:
          'Metabolic circuits that keep the heart rate up to maximise calorie '
          'burn while preserving muscle.',
    ),
    StarterPlan(
      id: 'plan_home3',
      name: 'Home Bodyweight 3-Day',
      split: 'Full body',
      daysPerWeek: 3,
      weeks: 6,
      goals: [FitnessGoal.generalFitness, FitnessGoal.loseWeight],
      experience: [ExperienceLevel.beginner],
      equipment: [EquipmentAccess.bodyweight, EquipmentAccess.bands],
      avgMinutes: 30,
      description:
          'No equipment needed — progressive bodyweight training you can do '
          'anywhere three days a week.',
    ),
    StarterPlan(
      id: 'plan_endurance4',
      name: 'Endurance Base 4-Day',
      split: 'Conditioning',
      daysPerWeek: 4,
      weeks: 8,
      goals: [FitnessGoal.endurance],
      experience: [
        ExperienceLevel.beginner,
        ExperienceLevel.intermediate,
        ExperienceLevel.advanced,
      ],
      equipment: [EquipmentAccess.bodyweight],
      avgMinutes: 40,
      description:
          'Build aerobic capacity with progressive intervals and steady-state '
          'conditioning across four sessions a week.',
    ),
  ];
}
