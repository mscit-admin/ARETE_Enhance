/// A single logged set: the weight lifted and reps completed.
class SetLog {
  const SetLog({
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    this.isPr = false,
  });

  final int setNumber;
  final double weightKg;
  final int reps;
  final bool isPr;

  /// Volume contribution of this set (kg lifted total).
  double get volume => weightKg * reps;

  /// Estimated one-rep-max via the Epley formula.
  double get estimated1RM => weightKg * (1 + reps / 30.0);
}
