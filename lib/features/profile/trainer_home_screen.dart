import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/member.dart';
import '../../data/models/trainer.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/gradient_avatar.dart';
import '../../shared/widgets/pill.dart';
import '../../shared/widgets/section_label.dart';
import '../../shared/widgets/stat_tile.dart';
import '../../state/profile_controller.dart';
import '../../state/trainer_controller.dart';
import '../coach/trainer_qr_screen.dart';
import 'settings_screen.dart';

/// Trainer-role home: the coach's own profile summary plus their client roster.
/// Demonstrates that the same app serves both roles (role switching).
class TrainerHomeScreen extends StatefulWidget {
  const TrainerHomeScreen({super.key});

  @override
  State<TrainerHomeScreen> createState() => _TrainerHomeScreenState();
}

class _TrainerHomeScreenState extends State<TrainerHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure roster is loaded when landing here directly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = context.read<TrainerController>();
      if (c.status == LoadStatus.idle) c.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrainerController>();

    return Scaffold(
      body: SafeArea(
        child: switch (controller.status) {
          LoadStatus.loading || LoadStatus.idle =>
            const Center(child: CircularProgressIndicator()),
          LoadStatus.error =>
            const Center(child: Text('Could not load clients.')),
          LoadStatus.ready => _TrainerBody(
              trainer: controller.trainer!,
              clients: controller.clients,
            ),
        },
      ),
    );
  }
}

class _TrainerBody extends StatelessWidget {
  const _TrainerBody({required this.trainer, required this.clients});

  final Trainer trainer;
  final List<Member> clients;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final active = clients
        .where((c) => c.membership.status == MembershipStatus.active)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.xxxl),
      children: [
        Row(
          children: [
            GradientAvatar(
              initials: initialsFrom(trainer.fullName),
              size: 50,
              tone: AvatarTone.ember,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Coach ${trainer.fullName.split(' ').first}',
                      style: context.textStyles.headlineSmall),
                  Text(trainer.specialty,
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: p.muted)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'My QR code',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TrainerQrScreen()),
              ),
              icon: const Icon(Icons.qr_code_2, color: AppColors.teal),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              icon: Icon(Icons.settings_outlined, color: p.text),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ShareCodeCard(),
        const SizedBox(height: AppSpacing.lg),

        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatTile(value: '${trainer.clientCount}', label: 'Clients'),
              StatTile(
                  value: '$active',
                  label: 'Active',
                  valueColor: AppColors.teal),
              StatTile(
                  value: trainer.rating.toStringAsFixed(1), label: 'Rating'),
              StatTile(
                  value: '~${trainer.avgResponseHours}h', label: 'Reply'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        SectionLabel('Your clients · ${clients.length}'),
        const SizedBox(height: AppSpacing.sm),
        for (final c in clients) ...[
          _ClientTile(member: c),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// Prompt for the trainer to open their shareable QR code.
class _ShareCodeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.ink,
      borderColor: AppColors.ink,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TrainerQrScreen()),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(Icons.qr_code_2, color: AppColors.brandGreen),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your coach QR code',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                Text('Clients scan it to connect with you',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white54),
        ],
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final onTrack = member.weeklyProgress >= 0.5;
    final tone = switch (member.membership.status) {
      MembershipStatus.active => onTrack ? PillTone.teal : PillTone.gold,
      MembershipStatus.frozen => PillTone.neutral,
      MembershipStatus.expired => PillTone.ember,
    };
    final statusText = member.membership.status == MembershipStatus.active
        ? '${member.sessionsThisWeek}/${member.weeklyTargetSessions} this week'
        : member.membership.status.label;

    return AppCard(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client detail — coming next')),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          GradientAvatar(initials: initialsFrom(member.fullName), size: 42),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName, style: context.textStyles.titleMedium),
                Text(
                  '${member.goal.label} · ${member.experience.label}',
                  style: context.textStyles.bodySmall?.copyWith(color: p.muted),
                ),
              ],
            ),
          ),
          Pill(statusText, tone: tone),
        ],
      ),
    );
  }
}
