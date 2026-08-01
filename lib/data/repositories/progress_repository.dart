import '../models/progress.dart';

/// Abstraction over progress data (charts, records, measurements).
abstract class ProgressRepository {
  Future<ProgressData> getProgress();
}
