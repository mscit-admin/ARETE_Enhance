import '../models/progress.dart';

/// Seeded 12-week progress history for the local-first build.
class MockProgress {
  MockProgress._();

  static ProgressData data() {
    // A gentle downward weight trend with realistic noise.
    const weights = [
      81.6, 81.2, 81.4, 80.7, 80.9, 80.1,
      79.8, 79.9, 79.2, 79.0, 78.6, 78.4,
    ];
    final base = DateTime(2026, 5, 9);
    final weight = [
      for (var i = 0; i < weights.length; i++)
        WeightPoint(date: base.add(Duration(days: 7 * i)), kg: weights[i]),
    ];

    const volumes = [
      8200, 9100, 8700, 9600, 10200, 9800,
      11000, 10600, 11800, 12100, 12600, 13200,
    ];
    final volume = [
      for (var i = 0; i < volumes.length; i++)
        VolumePoint(label: 'W${i + 1}', volumeKg: volumes[i].toDouble()),
    ];

    return ProgressData(
      weight: weight,
      volume: volume,
      records: [
        PersonalRecord(
            exercise: 'Barbell Bench Press',
            weightKg: 65,
            reps: 10,
            achievedOn: DateTime(2026, 7, 28)),
        PersonalRecord(
            exercise: 'Overhead Press',
            weightKg: 45,
            reps: 8,
            achievedOn: DateTime(2026, 7, 21)),
        PersonalRecord(
            exercise: 'Incline Dumbbell Press',
            weightKg: 26,
            reps: 12,
            achievedOn: DateTime(2026, 7, 14)),
        PersonalRecord(
            exercise: 'Cable Fly',
            weightKg: 17.5,
            reps: 15,
            achievedOn: DateTime(2026, 7, 7)),
      ],
      measurements: const [
        Measurement(
            label: 'Waist', value: 82, unit: 'cm', delta: -3.5, lowerIsBetter: true),
        Measurement(label: 'Chest', value: 104, unit: 'cm', delta: 1.5),
        Measurement(label: 'Arms', value: 38, unit: 'cm', delta: 1.2),
        Measurement(
            label: 'Body fat', value: 18, unit: '%', delta: -2.5, lowerIsBetter: true),
      ],
      totalWorkouts: 47,
      totalPRs: 9,
      streakDays: 24,
      photoCount: 3,
    );
  }
}
