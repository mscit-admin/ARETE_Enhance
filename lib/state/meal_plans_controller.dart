import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../data/models/nutrition.dart';

/// Trainer-side: the coach's named meal-plan templates, plus create/edit/
/// delete/assign — mirroring [PlansController] for workouts.
class MealPlansController extends ChangeNotifier {
  MealPlansController(this._client);

  final ApiClient _client;

  List<MealPlan> _plans = [];
  bool _loading = false;
  String? _error;

  List<MealPlan> get plans => _plans;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final j = await _client.get('/api/app/trainer/meal-plans')
          as Map<String, dynamic>;
      _plans = (j['rows'] as List)
          .map((e) => MealPlan.fromJson(e as Map<String, dynamic>))
          .toList();
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> createPlan(MealPlan plan) async {
    try {
      await _client.post('/api/app/trainer/meal-plans', {
        'name': plan.title,
        'description': plan.description,
        'days': plan.days.map((d) => d.toJson()).toList(),
      }, auth: true);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> updatePlan(String planId, MealPlan plan) async {
    try {
      await _client.put('/api/app/trainer/meal-plans/$planId', {
        'name': plan.title,
        'description': plan.description,
        'days': plan.days.map((d) => d.toJson()).toList(),
      });
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<MealPlan?> fetchDetail(String planId) async {
    try {
      final j = await _client.get('/api/app/trainer/meal-plans/$planId')
          as Map<String, dynamic>;
      return MealPlan.fromJson(j['plan'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<String?> deletePlan(String planId) async {
    try {
      await _client.delete('/api/app/trainer/meal-plans/$planId');
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Assign the plan to [memberIds]; optionally cross-link a workout plan that
  /// gets assigned to the same members.
  Future<String?> assign(
    String planId,
    List<String> memberIds, {
    String? workoutPlanId,
  }) async {
    try {
      await _client.post('/api/app/trainer/meal-plans/$planId/assign', {
        'memberIds': memberIds,
        if (workoutPlanId != null) 'workoutPlanId': workoutPlanId,
      }, auth: true);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<List<Map<String, dynamic>>> assignees(String planId) async {
    try {
      final j = await _client.get('/api/app/trainer/meal-plans/$planId/assignees')
          as Map<String, dynamic>;
      return (j['rows'] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<String?> unassign(String planId, String memberId) async {
    try {
      await _client.post(
        '/api/app/trainer/meal-plans/$planId/unassign',
        {'memberId': memberId},
        auth: true,
      );
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  void clear() {
    _plans = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }
}
