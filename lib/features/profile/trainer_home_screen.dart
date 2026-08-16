import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/gradient_avatar.dart';
import '../../shared/widgets/language_menu_button.dart';
import '../../shared/widgets/pill.dart';
import '../../shared/widgets/section_label.dart';
import '../../shared/widgets/stat_tile.dart';
import '../../state/connect_controller.dart';
import '../../state/profile_controller.dart';
import '../../state/session_controller.dart';
import '../coach/trainer_qr_screen.dart';
import '../notifications/notification_bell.dart';
import '../shell/root_scaffold_key.dart';
import '../trainer/nutrition_plan_screen.dart';

/// Trainer-role home: the signed-in trainer's own identity, their QR code and
/// their real linked clients. A quick icon switches back to trainee mode.
class TrainerHomeScreen extends StatefulWidget {
  const TrainerHomeScreen({super.key});

  @override
  State<TrainerHomeScreen> createState() => _TrainerHomeScreenState();
}

class _TrainerHomeScreenState extends State<TrainerHomeScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = context.read<ConnectController>();
      c.loadClients();
      c.loadTrainerCode();
    });
    // Newly-linked clients appear without a re-login.
    _poll = Timer.periodic(const Duration(seconds: 15),
        (_) => context.read<ConnectController>().loadClients());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
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
    final l = AppLocalizations.of(context);

    if (member == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final firstName = member.fullName.split(' ').first;
    final clients = connect.clients;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ---- Header: pinned, so the account, language and notification
            // controls stay reachable while the page scrolls ----
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                  AppSpacing.lg, AppSpacing.screen, AppSpacing.md),
              child: Row(
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
                        Text(l.trainerCoachName(firstName),
                            style: context.textStyles.headlineSmall),
                        Text(l.trainerWorkspace,
                            style: context.textStyles.bodySmall
                                ?.copyWith(color: p.muted)),
                      ],
                    ),
                  ),
                  // Quick switch to trainee mode.
                  IconButton(
                    tooltip: l.trainerSwitchToTrainee,
                    onPressed: () => context
                        .read<SessionController>()
                        .setRole(UserRole.member),
                    icon: const Icon(Icons.swap_horiz, color: AppColors.ember),
                  ),
                  const NotificationBell(),
                  LanguageMenuButton(color: p.text),
                  IconButton(
                    tooltip: l.profileSettingsTooltip,
                    onPressed: () =>
                        rootScaffoldKey.currentState?.openEndDrawer(),
                    icon: Icon(Icons.account_circle_outlined, color: p.text),
                  ),
                ],
              ),
            ),

            // ---- Everything below scrolls under the header ----
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0,
                    AppSpacing.screen, AppSpacing.xxxl),
                children: [
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
                        StatTile(
                            value: '${clients.length}',
                            label: l.trainerStatClients),
                        StatTile(
                            value: '${clients.length}',
                            label: l.trainerStatActive,
                            valueColor: AppColors.teal),
                        StatTile(
                            value: l.trainerPackagesSet,
                            label: l.trainerStatPackages),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  SectionLabel(l.trainerYourClients(clients.length)),
                  const SizedBox(height: AppSpacing.sm),
                  if (clients.isEmpty)
                    AppCard(
                      child: Column(
                        children: [
                          Icon(Icons.group_add_outlined, color: p.muted, size: 34),
                          const SizedBox(height: AppSpacing.sm),
                          Text(l.trainerNoClients,
                              style: context.textStyles.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            l.trainerShareQrHint,
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
                        memberId: (c['id'] as String?) ?? '',
                        name: (c['full_name'] as String?) ?? 'Client',
                        subtitle:
                            '${_pretty(c['goal'] as String?)} · ${_pretty(c['experience'] as String?)}',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                ],
              ),
            ),
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
    final l = AppLocalizations.of(context);
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
                Text(l.trainerYourCoachQr,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                Text(
                  code == null
                      ? l.trainerClientsScan
                      : l.trainerCodeShow(code!),
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
  const _ClientTile({
    required this.memberId,
    required this.name,
    required this.subtitle,
  });

  final String memberId;
  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
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
          Pill(l.trainerActive, tone: PillTone.teal),
          // Build this client's meal plan and water goal.
          IconButton(
            tooltip: l.coachNutritionMenuItem,
            icon: const Icon(Icons.restaurant_menu, color: AppColors.gold),
            onPressed: memberId.isEmpty
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CoachNutritionPlanScreen(
                          memberId: memberId,
                          memberName: name,
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
