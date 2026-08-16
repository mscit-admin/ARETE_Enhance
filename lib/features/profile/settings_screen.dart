import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/l10n/enum_labels.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_label.dart';
import '../../state/auth_controller.dart';
import '../../state/profile_controller.dart';
import '../../state/session_controller.dart';
import '../../state/trainer_controller.dart';
import '../alerts/alerts_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final profile = context.watch<ProfileController>();
    final member = profile.member;
    final l = AppLocalizations.of(context);
    // Only trainer accounts may switch into trainer mode.
    final isTrainerAccount =
        context.watch<AuthController>().user?.isTrainer ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          // ---- Role switch (trainer accounts only) ----
          if (isTrainerAccount) ...[
            SectionLabel(l.settingsViewingAs),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        session.isTrainer
                            ? Icons.sports_gymnastics
                            : Icons.directions_run,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                session.isTrainer
                                    ? l.roleTrainer
                                    : l.roleTrainee,
                                style: context.textStyles.titleMedium),
                            Text(
                              session.isTrainer
                                  ? l.settingsCoachView
                                  : l.settingsTraineeView,
                              style: context.textStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<UserRole>(
                    segments: [
                      ButtonSegment(
                          value: UserRole.member,
                          label: Text(l.roleTrainee),
                          icon: const Icon(Icons.directions_run)),
                      ButtonSegment(
                          value: UserRole.trainer,
                          label: Text(l.roleTrainer),
                          icon: const Icon(Icons.sports_gymnastics)),
                    ],
                    selected: {session.role},
                    onSelectionChanged: (s) {
                      context.read<SessionController>().setRole(s.first);
                      if (s.first == UserRole.trainer) {
                        context.read<TrainerController>().load();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // ---- Appearance ----
          SectionLabel(l.settingsAppearance),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  value: session.followSystemTheme,
                  onChanged: (v) =>
                      context.read<SessionController>().setFollowSystemTheme(v),
                  title: Text(l.settingsMatchSystemTheme),
                  activeColor: AppColors.accent,
                ),
                if (!session.followSystemTheme)
                  SwitchListTile(
                    value: session.isDark,
                    onChanged: (v) =>
                        context.read<SessionController>().setDark(v),
                    title: Text(l.settingsDarkMode),
                    activeColor: AppColors.accent,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ---- Alerts & reminders (water, meals, tips) ----
          SectionLabel(l.alertsTitle),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined,
                  color: AppColors.water),
              title: Text(l.alertsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AlertsScreen()),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ---- Preferences ----
          SectionLabel(l.settingsPreferences),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.straighten),
                  title: Text(l.settingsUnits),
                  trailing: Text(
                    (member?.units ?? UnitSystem.metric).localized(l),
                    style: context.textStyles.bodySmall,
                  ),
                ),
                const Divider(height: 1),
                _ToggleTile(
                    icon: Icons.notifications_outlined,
                    title: l.settingsWorkoutReminders,
                    initial: true),
                const Divider(height: 1),
                _ToggleTile(
                    icon: Icons.chat_outlined,
                    title: l.settingsCoachMessages,
                    initial: true),
                const Divider(height: 1),
                _ToggleTile(
                    icon: Icons.lock_outline,
                    title: l.settingsPrivatePhotos,
                    initial: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ---- Account ----
          SectionLabel(l.settingsAccount),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(l.settingsPrivacyData),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _notImplemented(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(l.settingsHelpSupport),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _notImplemented(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Text('ARETE · v0.1.0 (Phase 1)',
                style: context.textStyles.bodySmall),
          ),
        ],
      ),
    );
  }

  void _notImplemented(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).settingsComingLater)),
    );
  }
}

class _ToggleTile extends StatefulWidget {
  const _ToggleTile(
      {required this.icon, required this.title, required this.initial});
  final IconData icon;
  final String title;
  final bool initial;

  @override
  State<_ToggleTile> createState() => _ToggleTileState();
}

class _ToggleTileState extends State<_ToggleTile> {
  late bool _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(widget.icon),
      title: Text(widget.title),
      value: _value,
      activeColor: AppColors.accent,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}
