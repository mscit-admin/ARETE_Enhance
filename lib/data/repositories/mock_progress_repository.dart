import '../mock/mock_progress.dart';
import '../models/progress.dart';
import 'progress_repository.dart';

class MockProgressRepository implements ProgressRepository {
  @override
  Future<ProgressData> getProgress() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return MockProgress.data();
  }
}
