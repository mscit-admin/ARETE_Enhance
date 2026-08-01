import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/exercise.dart';
import '../data/models/set_log.dart';
import '../data/models/workout_session.dart';
import '../data/repositories/workout_repository.dart';
import 'profile_controller.dart';

/// Drives the active workout: loads today's session, tracks the current
/// exercise/set, the draft weight & reps, the rest timer, PR detection and
/// end-of-session stats.
class WorkoutController extends ChangeNotifier {
  WorkoutController(this._repo);

  final WorkoutRepository _repo;

  LoadStatus _status = LoadStatus.idle;
  WorkoutSession? _session;
  int _exerciseIndex = 0;

  double _draftWeight = 0;
  int _draftReps = 0;

  // Rest timer
  Timer? _restTimer;
  int _restRemaining = 0;
  int _restTotal = 0;

  LoadStatus get status => _status;
  WorkoutSession? get session => _session;
  int get exerciseIndex => _exerciseIndex;
  double get draftWeight => _draftWeight;
  int get draftReps => _draftReps;

  bool get isResting => _restTimer != null && _restRemaining > 0;
  int get restRemaining => _restRemaining;
  int get restTotal => _restTotal;
  double get restProgress => _restTotal == 0 ? 0 : _restRemaining / _restTotal;

  WorkoutExercise? get currentExercise =>
      _session == null ? null : _session!.exercises[_exerciseIndex];

  Exercise? get current => currentExercise?.exercise;

  bool get isLastExercise =>
      _session != null && _exerciseIndex >= _session!.exercises.length - 1;

  bool get currentExerciseComplete => currentExercise?.isComplete ?? false;

  Future<void> load() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _session = await _repo.getTodayWorkout();
      _exerciseIndex = 0;
      _resetDraftsForCurrent();
      _status = LoadStatus.ready;
    } catch (_) {
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  void start() {
    _session?.startedAt = DateTime.now();
    notifyListeners();
  }

  void _resetDraftsForCurrent() {
    final ex = current;
    if (ex == null) return;
    // Prefer where they left off last time, else the suggested working weight.
    _draftWeight = ex.lastWeightKg ?? ex.suggestedWeightKg;
    _draftReps = ex.targetReps;
  }

  void adjustWeight(double delta) {
    _draftWeight = (_draftWeight + delta).clamp(0, 1000).toDouble();
    notifyListeners();
  }

  void adjustReps(int delta) {
    _draftReps = (_draftReps + delta).clamp(0, 100).toInt();
    notifyListeners();
  }

  /// Log the current draft as a completed set; detect PRs and start rest.
  void logSet() {
    final we = currentExercise;
    if (we == null || _draftReps <= 0) return;

    final setNumber = we.loggedSets.length + 1;
    final candidate = SetLog(
      setNumber: setNumber,
      weightKg: _draftWeight,
      reps: _draftReps,
    );
    final prevBest = we.exercise.previousBest1RM ?? 0;
    final bestThisSession = we.loggedSets.isEmpty
        ? 0.0
        : we.loggedSets
            .map((s) => s.estimated1RM)
            .reduce((a, b) => a > b ? a : b);
    final isPr = candidate.estimated1RM > prevBest &&
        candidate.estimated1RM > bestThisSession;

    we.loggedSets.add(SetLog(
      setNumber: setNumber,
      weightKg: _draftWeight,
      reps: _draftReps,
      isPr: isPr,
    ));

    if (!we.isComplete) {
      _startRest(we.exercise.restSeconds);
    }
    notifyListeners();
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    _restTotal = seconds;
    _restRemaining = seconds;
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _restRemaining--;
      if (_restRemaining <= 0) {
        _restRemaining = 0;
        _restTimer?.cancel();
        _restTimer = null;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void addRest(int seconds) {
    if (!isResting) return;
    _restRemaining += seconds;
    _restTotal += seconds;
    notifyListeners();
  }

  void skipRest() {
    _restTimer?.cancel();
    _restTimer = null;
    _restRemaining = 0;
    notifyListeners();
  }

  void nextExercise() {
    if (_session == null || isLastExercise) return;
    skipRest();
    _exerciseIndex++;
    _resetDraftsForCurrent();
    notifyListeners();
  }

  Future<void> finish() async {
    skipRest();
    _session?.finishedAt = DateTime.now();
    if (_session != null) {
      await _repo.saveSession(_session!);
    }
    notifyListeners();
  }

  Duration get elapsed {
    final s = _session;
    if (s?.startedAt == null) return Duration.zero;
    final end = s!.finishedAt ?? DateTime.now();
    return end.difference(s.startedAt!);
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }
}
