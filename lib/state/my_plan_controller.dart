import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../data/models/trainer_plan.dart';

/// Member-side: the plan(s) a trainer has assigned to the current member.
class MyPlanController extends ChangeNotifier {
  MyPlanController(this._client);

  final ApiClient _client;

  List<TrainerPlan> _plans = [];
  bool _loaded = false;

  List<TrainerPlan> get plans => _plans;
  bool get loaded => _loaded;

  /// The active assigned plan, if any (most recent first).
  TrainerPlan? get current => _plans.isEmpty ? null : _plans.first;

  Future<void> load() async {
    try {
      final j = await _client.get('/api/app/my-plans') as Map<String, dynamic>;
      _plans = (j['rows'] as List)
          .map((e) => TrainerPlan.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Offline or no coach — leave whatever we had.
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// Log a completed session's real performance. [sets] items are
  /// {exerciseId?, exerciseName?, setNumber, weight, reps}. Returns null on
  /// success, else an error message.
  Future<String?> logSession({
    String? planId,
    int? dayIndex,
    String? title,
    required List<Map<String, dynamic>> sets,
  }) async {
    try {
      await _client.post('/api/app/sessions', {
        if (planId != null) 'planId': planId,
        if (dayIndex != null) 'dayIndex': dayIndex,
        if (title != null && title.isNotEmpty) 'title': title,
        'sets': sets,
      }, auth: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  void clear() {
    _plans = [];
    _loaded = false;
    notifyListeners();
  }
}
