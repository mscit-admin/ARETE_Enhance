import '../../core/constants/enums.dart';
import '../../data/models/assessment.dart';
import '../../data/models/starter_plan.dart';

/// A plan plus the score/reasons it earned against the member's answers.
class RankedPlan {
  const RankedPlan({required this.plan, required this.score, required this.reasons});
  final StarterPlan plan;
  final int score;
  final List<String> reasons;
}

/// Rule-based matcher: scores every plan against the assessment answers and
/// returns them best-first.
class PlanMatcher {
  const PlanMatcher();

  /// Expand what the member can actually use. Bodyweight is always available;
  /// a full gym also covers dumbbells and bands.
  Set<EquipmentAccess> _available(Set<EquipmentAccess> chosen) {
    final s = {...chosen, EquipmentAccess.bodyweight};
    if (s.contains(EquipmentAccess.fullGym)) {
      s..add(EquipmentAccess.dumbbells)..add(EquipmentAccess.bands);
    }
    return s;
  }

  List<RankedPlan> rank(AssessmentAnswers a, List<StarterPlan> plans) {
    final available = _available(a.equipment);
    final ranked = <RankedPlan>[];

    for (final p in plans) {
      var score = 0;
      final reasons = <String>[];

      if (a.goal != null && p.goals.contains(a.goal)) {
        score += 4;
        reasons.add('Matches your ${a.goal!.label.toLowerCase()} goal');
      }
      if (a.experience != null && p.experience.contains(a.experience)) {
        score += 3;
        reasons.add('Suited to ${a.experience!.label.toLowerCase()} lifters');
      }

      final dayGap = (p.daysPerWeek - a.daysPerWeek).abs();
      score += (3 - dayGap).clamp(-2, 3);
      if (dayGap == 0) {
        reasons.add('Fits your ${a.daysPerWeek} days per week');
      }

      final canDo = p.equipment.any(available.contains);
      if (canDo) {
        score += 3;
        reasons.add('Works with your equipment');
      } else {
        score -= 5;
      }

      ranked.add(RankedPlan(plan: p, score: score, reasons: reasons));
    }

    ranked.sort((x, y) => y.score.compareTo(x.score));
    return ranked;
  }
}
