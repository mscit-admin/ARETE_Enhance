import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/l10n/enum_labels.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/member.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/gradient_avatar.dart';
import '../../shared/widgets/language_menu_button.dart';
import '../../shared/widgets/section_label.dart';
import '../../state/assessment_controller.dart';
import '../../state/auth_controller.dart';
import '../../state/hydration_controller.dart';
import '../../state/nutrition_controller.dart';
import '../../state/profile_controller.dart';
import '../../state/session_controller.dart';
import '../alerts/widgets/daily_tip_card.dart';
import '../assessment/assessment_flow_screen.dart';
import '../assessment/starter_plan_detail_screen.dart';
import '../help/tour_keys.dart';
import '../nutrition/nutrition_screen.dart';
import '../notifications/notification_bell.dart';
import '../shell/root_scaffold_key.dart';
import 'widgets/badges_row.dart';
import 'widgets/goal_progress_card.dart';
import 'widgets/membership_card.dart';

/// Member home / profile — the first fully-built module of Phase 1.
class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: switch (controller.status) {
          LoadStatus.loading || LoadStatus.idle =>
            const Center(child: CircularProgressIndicator()),
          LoadStatus.error => _ErrorState(
              message: controller.error ?? l.profileSomethingWrong,
              onRetry: controller.load,
            ),
          LoadStatus.ready => _ProfileBody(member: controller.member!),
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final firstName = member.fullName.split(' ').first;
    final hydrationDue = context.watch<HydrationController>().promptDue;
    final isTrainerAccount =
        context.watch<AuthController>().user?.isTrainer ?? false;
    final l = AppLocalizations.of(context);

    return RefreshIndicator(
      onRefresh: context.read<ProfileController>().load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.xxxl),
        children: [
          // ---- Hydration reminder prompt (when due) ----
          if (hydrationDue) ...[
            const _HydrationPrompt(),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ---- Tip of the day (hides itself once dismissed) ----
          const DailyTipCard(),

          // ---- Header ----
          Row(
            children: [
              GradientAvatar(
                  initials: initialsFrom(member.fullName),
                  size: 50,
                  tone: AvatarTone.lime),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.profileHey(firstName),
                        style: context.textStyles.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      l.profileMemberStreak(member.membership.tier.localized(l),
                          member.currentStreakDays),
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: p.muted),
                    ),
                  ],
                ),
              ),
              if (isTrainerAccount)
                IconButton(
                  tooltip: l.profileSwitchTrainer,
                  onPressed: () => context
                      .read<SessionController>()
                      .setRole(UserRole.trainer),
                  icon: const Icon(Icons.sports_gymnastics,
                      color: AppColors.teal),
                ),
              const NotificationBell(),
              LanguageMenuButton(color: p.text),
              IconButton(
                key: TourKeys.homeAccount,
                tooltip: l.profileSettingsTooltip,
                onPressed: () => rootScaffoldKey.currentState?.openEndDrawer(),
                icon: Icon(Icons.account_circle_outlined, color: p.text),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ---- Streak banner (Carbon emphasis) ----
          KeyedSubtree(
            key: TourKeys.homeStreak,
            child: _StreakBanner(member: member),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ---- Assessment / plan entry ----
          const _AssessmentEntry(),
          const SizedBox(height: AppSpacing.xl),

          // ---- Today's activity (Carbon: three horizontal bars) ----
          KeyedSubtree(
            key: TourKeys.homeActivity,
            child: _TodayActivityBars(member: member),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ---- Today's session (visual entry to Workout Execution) ----
          SectionLabel(l.profileTodayWorkout),
          const SizedBox(height: AppSpacing.sm),
          KeyedSubtree(key: TourKeys.homeWorkout, child: _TodaySessionCard()),
          const SizedBox(height: AppSpacing.lg),

          // ---- Goal ----
          SectionLabel(l.profileGoalLabel(member.goal.localized(l))),
          const SizedBox(height: AppSpacing.sm),
          GoalProgressCard(member: member),
          const SizedBox(height: AppSpacing.lg),

          // ---- Membership ----
          SectionLabel(l.profileMembership),
          const SizedBox(height: AppSpacing.sm),
          MembershipCard(member: member),
          const SizedBox(height: AppSpacing.lg),

          // ---- Badges ----
          SectionLabel(l.profileAchievements),
          const SizedBox(height: AppSpacing.sm),
          BadgesRow(badges: member.badges),
          const SizedBox(height: AppSpacing.lg),

          // ---- Actions ----
        ],
      ),
    );
  }
}

class _TodaySessionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Carbon "Today's workout" hero: a bright white card that pops against the
    // black canvas, with a lime circular play button.
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.profilePushDay,
                  style: const TextStyle(
                    color: Color(0xFF0B0E11),
                    fontSize: 20,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.profileSessionMeta,
                  style: const TextStyle(
                    color: Color(0x990B0E11),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: AppColors.onAccent, size: 30),
          ),
        ],
      ),
    );
  }
}

/// Carbon streak banner — the big streak number over a lime flame tile.
class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.limeTintBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.limeTintBorder),
            ),
            child: const Icon(Icons.local_fire_department,
                color: AppColors.accent, size: 30),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${member.currentStreakDays}',
                        style: TextStyle(
                            fontSize: 40,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            color: p.text)),
                    const SizedBox(width: 6),
                    Text(l.streakDaysWord,
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(l.streakKeepGoing,
                    style:
                        context.textStyles.bodySmall?.copyWith(color: p.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carbon "Today's activity" — three horizontal metric bars (Move / Steps /
/// Water) plus a lime log-water chip. Replaces the old concentric KPI rings.
class _TodayActivityBars extends StatelessWidget {
  const _TodayActivityBars({required this.member});

  final Member member;

  static String _compact(int n) {
    if (n < 1000) return '$n';
    final k = n / 1000;
    return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ds = member.dailyStats;
    // Water is owned by the nutrition data (target + today's glasses); steps
    // and calories still come from the profile's daily stats.
    final nutrition = context.watch<NutritionController>();
    final overall =
        (((ds.caloriesProgress + ds.stepsProgress + nutrition.waterProgress) /
                    3) *
                100)
            .clamp(0.0, 100.0)
            .round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SectionLabel(l.profileTodayActivity)),
            Text('$overall%',
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ActivityBar(
          icon: Icons.local_fire_department,
          name: l.legendMove,
          value: '${ds.caloriesBurned}/${ds.caloriesTarget} kcal',
          progress: ds.caloriesProgress,
          color: AppColors.move,
        ),
        const SizedBox(height: AppSpacing.md),
        _ActivityBar(
          icon: Icons.directions_walk,
          name: l.kpiSteps,
          value: '${_compact(ds.steps)}/${_compact(ds.stepsTarget)}',
          progress: ds.stepsProgress,
          color: AppColors.steps,
        ),
        const SizedBox(height: AppSpacing.md),
        _ActivityBar(
          icon: Icons.water_drop,
          name: l.kpiWater,
          value: '${nutrition.waterGlasses}/${nutrition.waterTargetGlasses}',
          progress: nutrition.waterProgress,
          color: AppColors.water,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NutritionScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _LogWaterButton(),
      ],
    );
  }
}

class _ActivityBar extends StatelessWidget {
  const _ActivityBar({
    required this.icon,
    required this.name,
    required this.value,
    required this.progress,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String name;
  final String value;
  final double progress;
  final Color color;

  /// Optional destination — the water bar opens Meals & Drinks.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bar = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(name, style: context.textStyles.titleMedium),
            const Spacer(),
            Text(value,
                style: context.textStyles.bodySmall?.copyWith(color: p.muted)),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: p.muted),
            ],
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Container(height: 9, color: p.line),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(height: 9, color: color),
              ),
            ],
          ),
        ),
      ],
    );

    if (onTap == null) return bar;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: bar,
    );
  }
}

/// Entry point to the Health Assessment. Shows the selected plan once chosen.
class _AssessmentEntry extends StatelessWidget {
  const _AssessmentEntry();

  @override
  Widget build(BuildContext context) {
    final assessment = context.watch<AssessmentController>();
    final plan = assessment.selectedPlan;
    final p = context.palette;
    final l = AppLocalizations.of(context);

    return Material(
      color: plan == null ? AppColors.ink : p.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => plan == null
                ? const AssessmentFlowScreen()
                : StarterPlanDetailScreen(plan: plan),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: plan == null ? null : Border.all(color: p.line),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: plan == null
                      ? Colors.white.withValues(alpha: 0.12)
                      : p.emberSoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  plan == null ? Icons.assignment_outlined : Icons.check_circle,
                  color: plan == null ? Colors.white : AppColors.ember,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan == null ? l.assessGetStarter : l.assessYourPlan,
                      style: context.textStyles.titleMedium?.copyWith(
                          color: plan == null ? Colors.white : p.text),
                    ),
                    Text(
                      plan == null ? l.assessTake2min : plan.name,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: plan == null
                            ? Colors.white.withValues(alpha: 0.6)
                            : p.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: plan == null
                      ? Colors.white.withValues(alpha: 0.6)
                      : p.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// In-app hydration reminder. Appears when a reminder slot is due; confirming
/// logs a glass of water (which fills the water ring).
class _HydrationPrompt extends StatelessWidget {
  const _HydrationPrompt();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<HydrationController>();
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.water.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.water.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop, color: AppColors.water, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l.hydrateTitle,
                  style: context.textStyles.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.hydrateBody,
            style: context.textStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.water,
                  ),
                  onPressed: () {
                    controller.confirmDrank();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l.hydrateGlassLogged),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(l.hydrateIDrank),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton(
                onPressed: controller.snooze,
                child: Text(l.hydrateSnooze),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quick action to log a glass of water; updates the ring immediately.
class _LogWaterButton extends StatelessWidget {
  const _LogWaterButton();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return OutlinedButton.icon(
      onPressed: () {
        context.read<NutritionController>().logGlass();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.hydrateLogged),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      icon: const Icon(Icons.add, size: 18, color: AppColors.water),
      label: Text(l.hydrateLogGlass),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 40, color: p.muted),
            const SizedBox(height: AppSpacing.md),
            Text(l.profileCouldntLoad,
                style: context.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                textAlign: TextAlign.center,
                style: context.textStyles.bodySmall?.copyWith(color: p.muted)),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(onPressed: onRetry, child: Text(l.actionRetry)),
          ],
        ),
      ),
    );
  }
}
