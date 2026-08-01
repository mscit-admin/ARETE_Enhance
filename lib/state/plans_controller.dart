import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../data/models/trainer_plan.dart';

/// Trainer-side: the plans this trainer has authored, plus create/assign.
class PlansController extends ChangeNotifier {
  PlansController(this._client);

  final ApiClient _client;

  List<TrainerPlan> _plans = [];
  bool _loading = false;
  String? _error;

  List<TrainerPlan> get plans => _plans;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final j =
          await _client.get('/api/app/trainer/plans') as Map<String, dynamic>;
      _plans = (j['rows'] as List)
          .map((e) => TrainerPlan.fromJson(e as Map<String, dynamic>))
          .toList();
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Create a plan. Returns null on success, else an error message.
  Future<String?> createPlan({
    required String name,
    String description = '',
    int daysPerWeek = 3,
    int weeks = 8,
    required List<PlanExercise> exercises,
  }) async {
    try {
      await _client.post('/api/app/trainer/plans', {
        'name': name,
        'description': description,
        'daysPerWeek': daysPerWeek,
        'weeks': weeks,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      }, auth: true);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Fetch a plan's full detail (with exercises). Returns null on failure.
  Future<TrainerPlan?> fetchDetail(String planId) async {
    try {
      final j = await _client.get('/api/app/trainer/plans/$planId')
          as Map<String, dynamic>;
      return TrainerPlan.fromJson(j['plan'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Assign a plan to one of the trainer's clients.
  Future<String?> assign(String planId, String memberId) async {
    try {
      await _client.post(
        '/api/app/trainer/plans/$planId/assign',
        {'memberId': memberId},
        auth: true,
      );
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
