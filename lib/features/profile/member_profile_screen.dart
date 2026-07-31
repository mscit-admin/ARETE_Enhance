import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/member.dart';
import '../../shared/widgets/gradient_avatar.dart';
import '../../shared/widgets/pill.dart';
import '../../shared/widgets/section_label.dart';
import '../../state/hydration_controller.dart';
import '../../state/profile_controller.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'widgets/badges_row.dart';
import 'widgets/goal_progress_card.dart';
import 'widgets/kpi_ring.dart';
import 'widgets/membership_card.dart';

/// Member home / profile — the first fully-built module of Phase 1.
class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();

    return Scaffold(
      body: SafeArea(
        child: switch (controller.status) {
          LoadStatus.loading || LoadStatus.idle =>
            const Center(child: CircularProgressIndicator()),
          LoadStatus.error => _ErrorState(
              message: controller.error ?? 'Something went wrong.',
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

          // ---- Header ----
          Row(
            children: [
              GradientAvatar(initials: initialsFrom(member.fullName), size: 50),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hey, $firstName',
                        style: context.textStyles.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      '${member.membership.tier.label} Member · '
                      '${member.currentStreakDays}-day streak 🔥',
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: p.muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen()),
                ),
                icon: Icon(Icons.settings_outlined, color: p.text),
                tooltip: 'Settings',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ---- KPI ring: the home centrepiece ----
          const SectionLabel('Today at a glance'),
          const SizedBox(height: AppSpacing.md),
          Center(child: _TodayKpiRing(member: member)),
          const SizedBox(height: AppSpacing.lg),
          _RingLegend(member: member),
          const SizedBox(height: AppSpacing.md),
          const _LogWaterButton(),
          const SizedBox(height: AppSpacing.xl),

          // ---- Today's session (visual entry to Workout Execution) ----
          const SectionLabel('Today\'s workout'),
          const SizedBox(height: AppSpacing.sm),
          _TodaySessionCard(),
          const SizedBox(height: AppSpacing.lg),

          // ---- Goal ----
          SectionLabel('Goal · ${member.goal.label}'),
          const SizedBox(height: AppSpacing.sm),
          GoalProgressCard(member: member),
          const SizedBox(height: AppSpacing.lg),

          // ---- Membership ----
          const SectionLabel('Membership'),
          const SizedBox(height: AppSpacing.sm),
          MembershipCard(member: member),
          const SizedBox(height: AppSpacing.lg),

          // ---- Badges ----
          const SectionLabel('Achievements'),
          const SizedBox(height: AppSpacing.sm),
          BadgesRow(badges: member.badges),
          const SizedBox(height: AppSpacing.lg),

          // ---- Actions ----
          _ActionRow(
            icon: Icons.person_outline,
            label: 'Edit profile',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EditProfileScreen(member: member),
              ),
            ),
          ),
          _ActionRow(
            icon: Icons.settings_outlined,
            label: 'Settings & preferences',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySessionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Push Day · A',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '6 exercises · ~52 min',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Pill('Start ▸', tone: PillTone.ember),
        ],
      ),
    );
  }
}

/// The home centrepiece: three concentric activity rings (Move / Steps /
/// Water) wrapped around a 2×2 grid of the member's key KPI numbers.
class _TodayKpiRing extends StatelessWidget {
  const _TodayKpiRing({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final ds = member.dailyStats;

    final rings = [
      RingMetric(progress: ds.caloriesProgress, color: AppColors.move),
      RingMetric(progress: ds.stepsProgress, color: AppColors.steps),
      RingMetric(progress: ds.waterProgress, color: AppColors.water),
    ];

    return KpiRing(
      rings: rings,
      center: _RotatingKpiCenter(member: member),
    );
  }
}

/// The centre of the ring: shows ONE KPI large at a time, auto-advancing every
/// few seconds and also advancing on tap. Page dots show position.
class _RotatingKpiCenter extends StatefulWidget {
  const _RotatingKpiCenter({required this.member});

  final Member member;

  @override
  State<_RotatingKpiCenter> createState() => _RotatingKpiCenterState();
}

class _RotatingKpiCenterState extends State<_RotatingKpiCenter> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoRotate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRotate() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _index++);
    });
  }

  void _next() {
    setState(() => _index++);
    _startAutoRotate(); // reset the clock after a manual tap
  }

  List<_KpiSpec> _buildSpecs() {
    final m = widget.member;
    final ds = m.dailyStats;
    return [
      _KpiSpec(
        label: 'Water',
        value: '${ds.waterGlasses}',
        unit: 'of ${ds.waterTargetGlasses} glasses',
        icon: Icons.water_drop,
        color: AppColors.water,
      ),
      _KpiSpec(
        label: 'BMI',
        value: m.metrics.bmi.toStringAsFixed(1),
        unit: m.metrics.bmiCategory,
        icon: Icons.monitor_heart,
        color: AppColors.teal,
      ),
      _KpiSpec(
        label: 'Weight',
        value: m.displayWeight.toStringAsFixed(1),
        unit: m.units.weightUnit,
        icon: Icons.monitor_weight,
        color: AppColors.ember,
      ),
      _KpiSpec(
        label: 'Calories',
        value: '${ds.caloriesBurned}',
        unit: 'of ${ds.caloriesTarget} kcal',
        icon: Icons.local_fire_department,
        color: AppColors.move,
      ),
      _KpiSpec(
        label: 'Steps',
        value: _RingLegend._compact(ds.steps),
        unit: 'of ${_RingLegend._compact(ds.stepsTarget)}',
        icon: Icons.directions_walk,
        color: AppColors.steps,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final specs = _buildSpecs();
    final i = _index % specs.length;
    final spec = specs[i];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _next,
      child: SizedBox(
        width: 150,
        height: 138,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1).animate(anim),
                  child: child,
                ),
              ),
              child: Column(
                key: ValueKey(i),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(spec.icon, color: spec.color, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    spec.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                      color: p.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    spec.value,
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      height: 1.0,
                      color: p.text,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (spec.unit != null)
                    Text(
                      spec.unit!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.muted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int d = 0; d < specs.length; d++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: d == i ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: d == i ? spec.color : p.line,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiSpec {
  const _KpiSpec({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.unit,
  });

  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color color;
}

/// Colour key beneath the ring so each arc's metric is unambiguous.
class _RingLegend extends StatelessWidget {
  const _RingLegend({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final ds = member.dailyStats;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _LegendItem(
          color: AppColors.move,
          label: 'Move',
          reading: '${ds.caloriesBurned}/${ds.caloriesTarget} kcal',
        ),
        _LegendItem(
          color: AppColors.steps,
          label: 'Steps',
          reading: '${_compact(ds.steps)}/${_compact(ds.stepsTarget)}',
        ),
        _LegendItem(
          color: AppColors.water,
          label: 'Water',
          reading: '${ds.waterGlasses}/${ds.waterTargetGlasses} glasses',
        ),
      ],
    );
  }

  static String _compact(int n) {
    if (n < 1000) return '$n';
    final k = n / 1000;
    return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem(
      {required this.color, required this.label, required this.reading});

  final Color color;
  final String label;
  final String reading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          reading,
          style: TextStyle(
            fontSize: 11,
            color: p.muted,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
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
                  'Time to hydrate 💧',
                  style: context.textStyles.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Grab a glass of water and confirm below to keep your streak going.',
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
                      const SnackBar(
                        content: Text('Nice — glass logged 💧'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('I drank water'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton(
                onPressed: controller.snooze,
                child: const Text('Snooze'),
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
    return OutlinedButton.icon(
      onPressed: () {
        context.read<ProfileController>().logWater();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged a glass of water 💧'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      icon: const Icon(Icons.add, size: 18, color: AppColors.water),
      label: const Text('Log a glass of water'),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: p.text),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(label, style: context.textStyles.titleMedium),
              ),
              Icon(Icons.chevron_right, color: p.muted),
            ],
          ),
        ),
      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 40, color: p.muted),
            const SizedBox(height: AppSpacing.md),
            Text('Couldn\'t load your profile',
                style: context.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                textAlign: TextAlign.center,
                style: context.textStyles.bodySmall?.copyWith(color: p.muted)),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
