import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/member.dart';
import '../../shared/widgets/gradient_avatar.dart';
import '../../shared/widgets/pill.dart';
import '../../shared/widgets/section_label.dart';
import '../../state/profile_controller.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'widgets/badges_row.dart';
import 'widgets/goal_progress_card.dart';
import 'widgets/membership_card.dart';
import 'widgets/profile_metrics_card.dart';

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

    return RefreshIndicator(
      onRefresh: context.read<ProfileController>().load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.xxxl),
        children: [
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

          // ---- Metrics ----
          ProfileMetricsCard(member: member),
          const SizedBox(height: AppSpacing.lg),

          // ---- Today's session (visual entry to Workout Execution) ----
          const SectionLabel('Today'),
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
