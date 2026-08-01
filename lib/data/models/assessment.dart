import '../../core/constants/enums.dart';

/// The PAR-Q+ style safety questions asked before recommending a plan.
/// A "yes" to any flags a caution to consult a professional.
const List<String> parqQuestions = [
  'Has a doctor ever said you have a heart condition?',
  'Do you feel pain in your chest during physical activity?',
  'Do you lose balance from dizziness or lose consciousness?',
  'Do you have a bone or joint problem that could worsen with activity?',
  'Are you currently taking prescribed medication for blood pressure or heart?',
  'Do you know of any other reason you should not do physical activity?',
];

/// Answers collected across the assessment steps (mutated as the user goes).
class AssessmentAnswers {
  FitnessGoal? goal;
  ExperienceLevel? experience;
  int daysPerWeek = 3;
  final Set<EquipmentAccess> equipment = {EquipmentAccess.fullGym};
  ActivityLevel? activity;
  final List<bool> parq = List<bool>.filled(parqQuestions.length, false);

  bool get parqFlagged => parq.any((a) => a);

  bool get isComplete =>
      goal != null && experience != null && activity != null;
}
