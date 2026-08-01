import 'package:flutter/foundation.dart';

import '../data/models/progress.dart';
import '../data/repositories/progress_repository.dart';
import 'profile_controller.dart' show LoadStatus;

class ProgressController extends ChangeNotifier {
  ProgressController(this._repo);

  final ProgressRepository _repo;

  LoadStatus _status = LoadStatus.idle;
  ProgressData? _data;

  LoadStatus get status => _status;
  ProgressData? get data => _data;

  Future<void> load() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _data = await _repo.getProgress();
      _status = LoadStatus.ready;
    } catch (_) {
      _status = LoadStatus.error;
    }
    notifyListeners();
  }
}
