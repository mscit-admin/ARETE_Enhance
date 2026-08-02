import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/enums.dart';
import '../data/mock/mock_plans.dart';
import '../data/models/assessment.dart';
import '../data/models/starter_plan.dart';
import '../features/assessment/plan_matcher.dart';
import '../l10n/app_localizations.dart';

/// Holds the in-progress assessment answers, computes recommendations, and
/// remembers the plan the member chose (persisted across launches).
class AssessmentController extends ChangeNotifier {
  AssessmentController() {
    _restoreSelectedPlan();
  }

  static const _planKey = 'selected_starter_plan_v1';

  final AssessmentAnswers answers = AssessmentAnswers();
  final PlanMatcher _matcher = const PlanMatcher();

  List<RankedPlan> _recommendations = [];
  StarterPlan? _selectedPlan;

  List<RankedPlan> get recommendations => _recommendations;
  StarterPlan? get selectedPlan => _selectedPlan;
  bool get hasPlan => _selectedPlan != null;

  Future<void> _restoreSelectedPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_planKey);
    if (id == null) return;
    final plan = MockPlans.byId(id);
    if (plan != null) {
      _selectedPlan = plan;
      notifyListeners();
    }
  }

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

  void computeRecommendations(AppLocalizations l) {
    _recommendations = _matcher.rank(answers, MockPlans.all, l);
    notifyListeners();
  }

  Future<void> selectPlan(StarterPlan plan) async {
    _selectedPlan = plan;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planKey, plan.id);
  }

  /// Forget the chosen plan (e.g. on sign-out) so it doesn't leak across
  /// accounts.
  Future<void> clearSelectedPlan() async {
    _selectedPlan = null;
    _recommendations = [];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_planKey);
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
