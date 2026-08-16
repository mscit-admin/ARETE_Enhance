import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../data/models/meal_slot.dart';
import '../data/models/nutrition.dart';

/// Coach side: read and send one trainee's nutrition plan.
///
/// Scoped to whichever client the coach is currently editing — [load] resets
/// the state for that member.
class CoachNutritionController extends ChangeNotifier {
  CoachNutritionController(this._client);

  final ApiClient _client;

  String _memberId = '';
  CoachNutritionPlan? _plan;
  NutritionSettings? _current;
  bool _loading = false;
  bool _sending = false;
  String? _error;

  /// The plan this coach last sent to the member (null when there is none).
  CoachNutritionPlan? get plan => _plan;

  /// What the member is following right now — the starting point for a plan.
  NutritionSettings? get current => _current;

  bool get loading => _loading;
  bool get sending => _sending;
  String? get error => _error;

  Future<void> load(String memberId) async {
    _memberId = memberId;
    _loading = true;
    _error = null;
    _plan = null;
    _current = null;
    notifyListeners();
    try {
      final j = await _client
              .get('/api/app/trainer/trainees/$memberId/nutrition')
          as Map<String, dynamic>;
      final rawPlan = (j['plan'] as Map?)?.cast<String, dynamic>();
      _plan = rawPlan == null ? null : CoachNutritionPlan.fromJson(rawPlan);
      final rawCurrent = (j['current'] as Map?)?.cast<String, dynamic>();
      _current =
          rawCurrent == null ? null : NutritionSettings.fromJson(rawCurrent);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = null; // offline — the screen falls back to the defaults
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// The schedule to start editing from: the coach's last plan, else what the
  /// member follows today, else the app defaults.
  List<MealSlot> startingSchedule() {
    final fromPlan = _plan?.mealSchedule;
    if (fromPlan != null && fromPlan.isNotEmpty) return [...fromPlan];
    final fromMember = _current?.mealSchedule;
    if (fromMember != null && fromMember.isNotEmpty) {
      return [for (final s in fromMember) s.copyWith(source: MealSource.coach)];
    }
    return [
      for (final s in MealSlot.defaults()) s.copyWith(source: MealSource.coach),
    ];
  }

  int startingWaterTarget() =>
      _plan?.waterTargetGlasses ??
      _current?.waterTargetGlasses ??
      NutritionSettings.defaultTargetGlasses;

  /// Send the plan. Returns null on success, else a message to show.
  Future<String?> send({
    required List<MealSlot> mealSchedule,
    required int waterTargetGlasses,
    int durationDays = 0,
    String note = '',
  }) async {
    if (_memberId.isEmpty) return 'No client selected';
    if (mealSchedule.isEmpty) return 'Add at least one meal';
    _sending = true;
    notifyListeners();
    try {
      final j = await _client.post(
        '/api/app/trainer/trainees/$_memberId/nutrition',
        {
          'mealSchedule': [for (final s in mealSchedule) s.toJson()],
          'waterTargetGlasses': waterTargetGlasses,
          'durationDays': durationDays,
          'note': note,
        },
        auth: true,
      ) as Map<String, dynamic>;
      final rawPlan = (j['plan'] as Map?)?.cast<String, dynamic>();
      if (rawPlan != null) _plan = CoachNutritionPlan.fromJson(rawPlan);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      _sending = false;
      notifyListeners();
    }
  }
}
