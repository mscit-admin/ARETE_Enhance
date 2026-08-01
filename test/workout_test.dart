import 'package:arete/data/models/set_log.dart';
import 'package:arete/data/repositories/mock_workout_repository.dart';
import 'package:arete/state/workout_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SetLog', () {
    test('volume is weight × reps', () {
      const s = SetLog(setNumber: 1, weightKg: 60, reps: 10);
      expect(s.volume, 600);
    });

    test('estimated 1RM uses Epley', () {
      const s = SetLog(setNumber: 1, weightKg: 60, reps: 10);
      // 60 * (1 + 10/30) = 80
      expect(s.estimated1RM, closeTo(80, 0.001));
    });
  });

  group('WorkoutController', () {
    test('logs sets, accumulates volume and detects a PR', () async {
      final c = WorkoutController(MockWorkoutRepository());
      await c.load();
      c.start();

      // Bench: previousBest1RM = 78, defaults to 57.5kg × 10 (1RM ≈ 76.7) → no PR.
      c.logSet();
      expect(c.currentExercise!.loggedSets.first.isPr, isFalse);

      // Bump to 65kg × 10 (1RM ≈ 86.7) → beats previous best → PR.
      c.adjustWeight(7.5);
      c.logSet();
      expect(c.currentExercise!.loggedSets[1].isPr, isTrue);

      expect(c.session!.totalVolume, closeTo(57.5 * 10 + 65 * 10, 0.01));
      expect(c.session!.completedSets, 2);

      c.dispose();
    });

    test('advancing to the next exercise resets the draft', () async {
      final c = WorkoutController(MockWorkoutRepository());
      await c.load();
      final firstDraft = c.draftWeight;
      c.nextExercise();
      expect(c.exerciseIndex, 1);
      // Second exercise has a different suggested/last weight.
      expect(c.draftWeight, isNot(equals(firstDraft)));
      c.dispose();
    });
  });
}
