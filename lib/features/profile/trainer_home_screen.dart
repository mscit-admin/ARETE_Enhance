import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/gradient_avatar.dart';
import '../../shared/widgets/pill.dart';
import '../../shared/widgets/section_label.dart';
import '../../shared/widgets/stat_tile.dart';
import '../../state/connect_controller.dart';
import '../../state/profile_controller.dart';
import '../../state/session_controller.dart';
import '../coach/trainer_qr_screen.dart';
import 'settings_screen.dart';

/// Trainer-role home: the signed-in trainer's own identity, their QR code and
/// their real linked clients. A quick icon switches back to trainee mode.
class TrainerHomeScreen extends StatefulWidget {
  const TrainerHomeScreen({super.key});

  @override
  State<TrainerHomeScreen> createState() => _TrainerHomeScreenState();
}

class _TrainerHomeScreenState extends State<TrainerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = context.read<ConnectController>();
      c.loadClients();
      c.loadTrainerCode();
    });
  }

  static String _pretty(String? s) {
    if (s == null || s.isEmpty) return '—';
    final words = s.replaceAll('_', ' ').split(' ');
    return words
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final connect = context.watch<ConnectController>();
    final member = profile.member;
    final p = context.palette;

    if (member == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final firstName = member.fullName.split(' ').first;
    final clients = connect.clients;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg,
              AppSpacing.screen, AppSpacing.xxxl),
          children: [
            // ---- Header: the trainer's own name ----
            Row(
              children: [
                GradientAvatar(
                  initials: initialsFrom(member.fullName),
                  size: 50,
                  tone: AvatarTone.ember,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Coach $firstName',
                          style: context.textStyles.headlineSmall),
                      Text('Trainer workspace',
                          style: context.textStyles.bodySmall
                              ?.copyWith(color: p.muted)),
                    ],
                  ),
                ),
                // Quick switch to trainee mode.
                IconButton(
                  tooltip: 'Switch to trainee mode',
                  onPressed: () => context
                      .read<SessionController>()
                      .setRole(UserRole.member),
                  icon: const Icon(Icons.swap_horiz, color: AppColors.ember),
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

            // ---- Share QR ----
            _ShareCodeCard(code: connect.trainerCode),
            const SizedBox(height: AppSpacing.lg),

            // ---- Stats ----
            AppCard(
              padding: const EdgeInsets.symmetric(
                  vertical: 16, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatTile(value: '${clients.length}', label: 'Clients'),
                  StatTile(
                      value: '${clients.length}',
                      label: 'Active',
                      valueColor: AppColors.teal),
                  const StatTile(value: 'Set', label: 'Packages'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            SectionLabel('Your clients · ${clients.length}'),
            const SizedBox(height: AppSpacing.sm),
            if (clients.isEmpty)
              AppCard(
                child: Column(
                  children: [
                    Icon(Icons.group_add_outlined, color: p.muted, size: 34),
                    const SizedBox(height: AppSpacing.sm),
                    Text('No clients yet',
                        style: context.textStyles.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Share your QR code — trainees scan it to connect with you.',
                      textAlign: TextAlign.center,
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: p.muted),
                    ),
                  ],
                ),
              )
            else
              for (final c in clients) ...[
                _ClientTile(
                  name: (c['full_name'] as String?) ?? 'Client',
                  subtitle:
                      '${_pretty(c['goal'] as String?)} · ${_pretty(c['experience'] as String?)}',
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        ),
      ),
    );
  }
}

/// Prompt for the trainer to open their shareable QR code.
class _ShareCodeCard extends StatelessWidget {
  const _ShareCodeCard({this.code});
  final String? code;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your coach QR code',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                Text(
                  code == null
                      ? 'Clients scan it to connect with you'
                      : 'Code: $code · tap to show QR',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
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
  const _ClientTile({required this.name, required this.subtitle});

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          GradientAvatar(initials: initialsFrom(name), size: 42),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.textStyles.titleMedium),
                Text(subtitle,
                    style: context.textStyles.bodySmall
                        ?.copyWith(color: p.muted)),
              ],
            ),
          ),
          const Pill('Active', tone: PillTone.teal),
        ],
      ),
    );
  }
}
