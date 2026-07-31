import 'package:flutter/foundation.dart';

import '../data/models/member.dart';
import '../data/models/trainer.dart';
import '../data/repositories/profile_repository.dart';
import 'profile_controller.dart';

/// Backs the trainer-role views: the trainer's own profile and their client
/// roster.
class TrainerController extends ChangeNotifier {
  TrainerController(this._repo);

  final ProfileRepository _repo;

  LoadStatus _status = LoadStatus.idle;
  Trainer? _trainer;
  List<Member> _clients = const [];

  LoadStatus get status => _status;
  Trainer? get trainer => _trainer;
  List<Member> get clients => _clients;

  Future<void> load() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _trainer = await _repo.getTrainerProfile();
      _clients = await _repo.getClientsForTrainer(_trainer!.id);
      _status = LoadStatus.ready;
    } catch (_) {
      _status = LoadStatus.error;
    }
    notifyListeners();
  }
}
