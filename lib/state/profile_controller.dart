import 'package:flutter/foundation.dart';

import '../data/models/member.dart';
import '../data/models/trainer.dart';
import '../data/repositories/profile_repository.dart';

enum LoadStatus { idle, loading, ready, error }

/// Exposes the current member (and their assigned trainer) to the UI and
/// mediates updates through the repository.
class ProfileController extends ChangeNotifier {
  ProfileController(this._repo);

  final ProfileRepository _repo;

  LoadStatus _status = LoadStatus.idle;
  Member? _member;
  Trainer? _assignedTrainer;
  String? _error;

  LoadStatus get status => _status;
  Member? get member => _member;
  Trainer? get assignedTrainer => _assignedTrainer;
  String? get error => _error;

  Future<void> load() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _member = await _repo.getCurrentMember();
      _assignedTrainer = await _repo.getAssignedTrainer(_member!.id);
      _status = LoadStatus.ready;
    } catch (e) {
      _error = e.toString();
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> save(Member updated) async {
    // Optimistic update for a snappy UI.
    final previous = _member;
    _member = updated;
    notifyListeners();
    try {
      _member = await _repo.updateMember(updated);
    } catch (e) {
      _member = previous;
      _error = e.toString();
    }
    notifyListeners();
  }
}
