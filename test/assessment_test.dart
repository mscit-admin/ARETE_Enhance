import 'package:arete/core/constants/enums.dart';
import 'package:arete/data/mock/mock_plans.dart';
import 'package:arete/data/models/assessment.dart';
import 'package:arete/features/assessment/plan_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const matcher = PlanMatcher();

  test('intermediate muscle-builder with a full gym gets Upper/Lower', () {
    final a = AssessmentAnswers()
      ..goal = FitnessGoal.buildMuscle
      ..experience = ExperienceLevel.intermediate
      ..daysPerWeek = 4
      ..activity = ActivityLevel.moderate;
    a.equipment
      ..clear()
      ..add(EquipmentAccess.fullGym);

    final ranked = matcher.rank(a, MockPlans.all);
    expect(ranked.first.plan.id, 'plan_upperlower4');
    expect(ranked.first.reasons, isNotEmpty);
  });

  test('bodyweight-only beginner gets a home plan, not a gym plan', () {
    final a = AssessmentAnswers()
      ..goal = FitnessGoal.generalFitness
      ..experience = ExperienceLevel.beginner
      ..daysPerWeek = 3
      ..activity = ActivityLevel.light;
    a.equipment
      ..clear()
      ..add(EquipmentAccess.bodyweight);

    final ranked = matcher.rank(a, MockPlans.all);
    expect(ranked.first.plan.id, 'plan_home3');
    // A full-gym plan must not win when there's no gym access.
    expect(ranked.first.plan.equipment.contains(EquipmentAccess.fullGym),
        isFalse);
  });

  test('PAR-Q flags when any answer is yes', () {
    final a = AssessmentAnswers();
    expect(a.parqFlagged, isFalse);
    a.parq[0] = true;
    expect(a.parqFlagged, isTrue);
  });
}
