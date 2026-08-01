import 'package:arete/data/mock/mock_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProgressData', () {
    final data = MockProgress.data();

    test('weight change is last minus first', () {
      expect(data.weightChange, closeTo(78.4 - 81.6, 0.001));
    });

    test('this-week volume is the latest point', () {
      expect(data.thisWeekVolume, 13200);
    });

    test('has 12 weekly points for both series', () {
      expect(data.weight.length, 12);
      expect(data.volume.length, 12);
    });

    test('waist improves when it goes down', () {
      final waist = data.measurements.firstWhere((m) => m.label == 'Waist');
      expect(waist.lowerIsBetter, isTrue);
      expect(waist.improved, isTrue); // delta is negative
    });
  });
}
