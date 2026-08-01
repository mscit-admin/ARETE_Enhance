import 'package:flutter/foundation.dart';

import '../core/constants/enums.dart';
import '../data/mock/mock_plans.dart';
import '../data/models/assessment.dart';
import '../data/models/starter_plan.dart';
import '../features/assessment/plan_matcher.dart';

/// Holds the in-progress assessment answers, computes recommendations, and
/// remembers the plan the member chose.
class AssessmentController extends ChangeNotifier {
  final AssessmentAnswers answers = AssessmentAnswers();
  final PlanMatcher _matcher = const PlanMatcher();

  List<RankedPlan> _recommendations = [];
  StarterPlan? _selectedPlan;

  List<RankedPlan> get recommendations => _recommendations;
  StarterPlan? get selectedPlan => _selectedPlan;
  bool get hasPlan => _selectedPlan != null;

  void setGoal(FitnessGoal g) {
    answers.goal = g;
    notifyListeners();
  }

  void setExperience(ExperienceLevel e) {
    answers.experience = e;
    notifyListeners();
  }

  void setDays(int d) {
    answers.daysPerWeek = d;
    notifyListeners();
  }

  void toggleEquipment(EquipmentAccess e) {
    if (answers.equipment.contains(e)) {
      answers.equipment.remove(e);
    } else {
      answers.equipment.add(e);
    }
    notifyListeners();
  }

  void setActivity(ActivityLevel a) {
    answers.activity = a;
    notifyListeners();
  }

  void setParq(int index, bool value) {
    answers.parq[index] = value;
    notifyListeners();
  }

  void computeRecommendations() {
    _recommendations = _matcher.rank(answers, MockPlans.all);
    notifyListeners();
  }

  void selectPlan(StarterPlan plan) {
    _selectedPlan = plan;
    notifyListeners();
  }

  void reset() {
    answers
      ..goal = null
      ..experience = null
      ..daysPerWeek = 3
      ..activity = null;
    answers.equipment
      ..clear()
      ..add(EquipmentAccess.fullGym);
    for (var i = 0; i < answers.parq.length; i++) {
      answers.parq[i] = false;
    }
    _recommendations = [];
    notifyListeners();
  }
}
