import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pill.dart';
import '../../shared/widgets/section_label.dart';
import '../../state/profile_controller.dart';
import '../../state/session_controller.dart';
import '../../state/trainer_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final profile = context.watch<ProfileController>();
    final member = profile.member;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          // ---- Role switch (one app, two roles) ----
          const SectionLabel('Viewing as'),
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
                      color: AppColors.ember,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(session.role.label,
                              style: context.textStyles.titleMedium),
                          Text(
                            session.isTrainer
                                ? 'Coach view — client roster & plans'
                                : 'Your training experience',
                            style: context.textStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Pill('Demo switch', tone: PillTone.neutral),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<UserRole>(
                  segments: const [
                    ButtonSegment(
                        value: UserRole.member,
                        label: Text('Member'),
                        icon: Icon(Icons.directions_run)),
                    ButtonSegment(
                        value: UserRole.trainer,
                        label: Text('Trainer'),
                        icon: Icon(Icons.sports_gymnastics)),
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

          // ---- Appearance ----
          const SectionLabel('Appearance'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  value: session.followSystemTheme,
                  onChanged: (v) =>
                      context.read<SessionController>().setFollowSystemTheme(v),
                  title: const Text('Match system theme'),
                  activeColor: AppColors.ember,
                ),
                if (!session.followSystemTheme)
                  SwitchListTile(
                    value: session.isDark,
                    onChanged: (v) =>
                        context.read<SessionController>().setDark(v),
                    title: const Text('Dark mode'),
                    activeColor: AppColors.ember,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ---- Preferences ----
          const SectionLabel('Preferences'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.straighten),
                  title: const Text('Units'),
                  trailing: Text(
                    member?.units.label ?? UnitSystem.metric.label,
                    style: context.textStyles.bodySmall,
                  ),
                ),
                const Divider(height: 1),
                const _ToggleTile(
                    icon: Icons.notifications_outlined,
                    title: 'Workout reminders',
                    initial: true),
                const Divider(height: 1),
                const _ToggleTile(
                    icon: Icons.chat_outlined,
                    title: 'Coach messages',
                    initial: true),
                const Divider(height: 1),
                const _ToggleTile(
                    icon: Icons.lock_outline,
                    title: 'Private progress photos',
                    initial: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ---- Account ----
          const SectionLabel('Account'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Privacy & data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _notImplemented(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _notImplemented(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.danger),
                  title: const Text('Log out',
                      style: TextStyle(color: AppColors.danger)),
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
      const SnackBar(content: Text('Coming in a later phase')),
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
      activeColor: AppColors.ember,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}
