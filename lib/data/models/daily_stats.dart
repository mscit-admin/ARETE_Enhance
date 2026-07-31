/// Today's activity counters shown in the home KPI ring.
/// In the local-first build these are seeded and mutated in memory; later they
/// come from the backend / health integrations.
class DailyStats {
  const DailyStats({
    required this.waterGlasses,
    required this.waterTargetGlasses,
    required this.steps,
    required this.stepsTarget,
    required this.caloriesBurned,
    required this.caloriesTarget,
    required this.activeMinutes,
    required this.activeMinutesTarget,
  });

  final int waterGlasses;
  final int waterTargetGlasses;
  final int steps;
  final int stepsTarget;
  final int caloriesBurned;
  final int caloriesTarget;
  final int activeMinutes;
  final int activeMinutesTarget;

  /// One glass = 250 ml.
  double get waterLiters => waterGlasses * 0.25;

  double get waterProgress =>
      waterTargetGlasses == 0 ? 0 : waterGlasses / waterTargetGlasses;
  double get stepsProgress => stepsTarget == 0 ? 0 : steps / stepsTarget;
  double get caloriesProgress =>
      caloriesTarget == 0 ? 0 : caloriesBurned / caloriesTarget;
  double get activeProgress =>
      activeMinutesTarget == 0 ? 0 : activeMinutes / activeMinutesTarget;

  /// Average of the three ring metrics, clamped 0..1 — drives the "today"
  /// completion figure.
  double get overallProgress {
    final v = (waterProgress.clamp(0.0, 1.0) +
            stepsProgress.clamp(0.0, 1.0) +
            caloriesProgress.clamp(0.0, 1.0)) /
        3;
    return v;
  }

  DailyStats copyWith({
    int? waterGlasses,
    int? waterTargetGlasses,
    int? steps,
    int? stepsTarget,
    int? caloriesBurned,
    int? caloriesTarget,
    int? activeMinutes,
    int? activeMinutesTarget,
  }) {
    return DailyStats(
      waterGlasses: waterGlasses ?? this.waterGlasses,
      waterTargetGlasses: waterTargetGlasses ?? this.waterTargetGlasses,
      steps: steps ?? this.steps,
      stepsTarget: stepsTarget ?? this.stepsTarget,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      caloriesTarget: caloriesTarget ?? this.caloriesTarget,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      activeMinutesTarget: activeMinutesTarget ?? this.activeMinutesTarget,
    );
  }
}
