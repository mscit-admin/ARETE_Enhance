import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_label.dart';
import '../../state/auth_controller.dart';
import '../../state/hydration_controller.dart';
import '../../state/locale_controller.dart';
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
                        color: AppColors.ember,
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

          // ---- Language ----
          SectionLabel(l.settingsLanguage),
          const SizedBox(height: AppSpacing.sm),
          const _LanguageSection(),
          const SizedBox(height: AppSpacing.xl),

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
                  activeColor: AppColors.ember,
                ),
                if (!session.followSystemTheme)
                  SwitchListTile(
                    value: session.isDark,
                    onChanged: (v) =>
                        context.read<SessionController>().setDark(v),
                    title: Text(l.settingsDarkMode),
                    activeColor: AppColors.ember,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ---- Hydration reminders ----
          SectionLabel(l.settingsHydration),
          const SizedBox(height: AppSpacing.sm),
          const _HydrationSection(),
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
                    member?.units.label ?? UnitSystem.metric.label,
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
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.danger),
                  title: Text(l.settingsLogout,
                      style: const TextStyle(color: AppColors.danger)),
                  onTap: () => _logout(context),
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

  Future<void> _logout(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.logoutConfirmTitle),
        content: Text(l.logoutConfirmBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.actionCancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.settingsLogout)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthController>().signOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }
}

/// Language picker — English, العربية, Français. Selecting Arabic flips the
/// whole app to RTL automatically. "System default" clears the override.
class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocaleController>();
    final l = AppLocalizations.of(context);
    final current = controller.locale?.languageCode;

    Widget tile(String? code, String label) {
      return RadioListTile<String?>(
        value: code,
        groupValue: current,
        activeColor: AppColors.ember,
        onChanged: (v) => context
            .read<LocaleController>()
            .setLocale(v == null ? null : Locale(v)),
        title: Text(label),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          tile('en', l.langEnglish),
          const Divider(height: 1),
          tile('ar', l.langArabic),
          const Divider(height: 1),
          tile('fr', l.langFrench),
        ],
      ),
    );
  }
}

/// Hydration reminder controls: enable, cadence, window, permission and tests.
class _HydrationSection extends StatelessWidget {
  const _HydrationSection();

  static String _fmtHour(int h) {
    final period = h < 12 ? 'AM' : 'PM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12 $period';
  }

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HydrationController>();
    final p = context.palette;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.water_drop_outlined),
            title: const Text('Remind me to drink water'),
            subtitle: Text(
              h.enabled
                  ? 'Every ${h.intervalHours}h · ${_fmtHour(h.startHour)}–${_fmtHour(h.endHour)}'
                  : 'Off',
            ),
            value: h.enabled,
            activeColor: AppColors.water,
            onChanged: (v) => context.read<HydrationController>().setEnabled(v),
          ),
          if (h.enabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.timelapse),
              title: const Text('Reminder every'),
              trailing: DropdownButton<int>(
                value: h.intervalHours,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 hour')),
                  DropdownMenuItem(value: 2, child: Text('2 hours')),
                  DropdownMenuItem(value: 3, child: Text('3 hours')),
                ],
                onChanged: (v) => v == null
                    ? null
                    : context.read<HydrationController>().setIntervalHours(v),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Active window'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HourDropdown(
                    value: h.startHour,
                    options: const [6, 7, 8, 9, 10],
                    onChanged: (v) => context
                        .read<HydrationController>()
                        .setWindow(startHour: v),
                  ),
                  Text('  –  ', style: TextStyle(color: p.muted)),
                  _HourDropdown(
                    value: h.endHour,
                    options: const [17, 18, 19, 20, 21, 22],
                    onChanged: (v) => context
                        .read<HydrationController>()
                        .setWindow(endHour: v),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                h.permissionGranted
                    ? Icons.notifications_active
                    : Icons.notifications_off_outlined,
                color: h.permissionGranted ? AppColors.teal : AppColors.warning,
              ),
              title: const Text('System notifications'),
              subtitle: Text(h.permissionGranted ? 'Allowed' : 'Not allowed'),
              trailing: h.permissionGranted
                  ? null
                  : TextButton(
                      onPressed: () =>
                          context.read<HydrationController>().requestPermission(),
                      child: const Text('Enable'),
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<HydrationController>().sendTestNotification();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test notification sent'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications, size: 18),
                      label: const Text('Test'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context
                            .read<HydrationController>()
                            .triggerInAppPromptNow();
                        Navigator.of(context).maybePop();
                      },
                      icon: const Icon(Icons.touch_app, size: 18),
                      label: const Text('In-app'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HourDropdown extends StatelessWidget {
  const _HourDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    // Guarantee the current value is selectable even if outside the presets.
    final items = {...options, value}.toList()..sort();
    return DropdownButton<int>(
      value: value,
      underline: const SizedBox.shrink(),
      items: [
        for (final h in items)
          DropdownMenuItem(value: h, child: Text(_HydrationSection._fmtHour(h))),
      ],
      onChanged: (v) => v == null ? null : onChanged(v),
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
