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

  void clear() {
    _plans = [];
    _loaded = false;
    notifyListeners();
  }
}
