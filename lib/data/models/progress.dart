/// A body-weight measurement at a point in time.
class WeightPoint {
  const WeightPoint({required this.date, required this.kg});
  final DateTime date;
  final double kg;
}

/// Training volume for one week (total kg lifted).
class VolumePoint {
  const VolumePoint({required this.label, required this.volumeKg});
  final String label;
  final double volumeKg;
}

/// A personal record on a lift.
class PersonalRecord {
  const PersonalRecord({
    required this.exercise,
    required this.weightKg,
    required this.reps,
    required this.achievedOn,
  });

  final String exercise;
  final double weightKg;
  final int reps;
  final DateTime achievedOn;
}

/// A tracked body measurement with its change over the period.
class Measurement {
  const Measurement({
    required this.label,
    required this.value,
    required this.unit,
    required this.delta,
    this.lowerIsBetter = false,
  });

  final String label;
  final double value;
  final String unit;

  /// Signed change over the tracked window (e.g. -2.0).
  final double delta;

  /// Whether a decrease is an improvement (waist, body fat) vs increase (arms).
  final bool lowerIsBetter;

  bool get improved => lowerIsBetter ? delta < 0 : delta > 0;
  bool get unchanged => delta == 0;
}

/// Aggregate of everything shown on the Progress dashboard.
class ProgressData {
  const ProgressData({
    required this.weight,
    required this.volume,
    required this.records,
    required this.measurements,
    required this.totalWorkouts,
    required this.totalPRs,
    required this.streakDays,
    required this.photoCount,
  });

  final List<WeightPoint> weight;
  final List<VolumePoint> volume;
  final List<PersonalRecord> records;
  final List<Measurement> measurements;
  final int totalWorkouts;
  final int totalPRs;
  final int streakDays;
  final int photoCount;

  double get currentWeight => weight.isEmpty ? 0 : weight.last.kg;
  double get startWeight => weight.isEmpty ? 0 : weight.first.kg;
  double get weightChange => currentWeight - startWeight;

  double get thisWeekVolume => volume.isEmpty ? 0 : volume.last.volumeKg;
}
