import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/gradient_avatar.dart';
import '../../state/auth_controller.dart';
import '../../state/profile_controller.dart';
import '../help/tour_keys.dart';
import '../library/exercise_library_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

/// Side menu opened from the account icon in a screen header. Holds the
/// account actions — edit profile and log out.
class AccountDrawer extends StatelessWidget {
  const AccountDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    final l = AppLocalizations.of(context);
    // Capture the pieces we need up front — closing the drawer/overlays later
    // would otherwise leave this widget's context defunct.
    final auth = context.read<AuthController>();
    final rootNav = Navigator.of(context, rootNavigator: true);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l.logoutConfirmTitle),
        content: Text(l.logoutConfirmBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(l.actionCancel)),
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(l.settingsLogout)),
        ],
      ),
    );
    if (confirmed != true) return;
    await auth.signOut();
    // Close the drawer, any pushed screens and dialogs — the AuthGate then
    // swaps in the sign-in screen automatically.
    rootNav.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final member = context.watch<ProfileController>().member;
    final p = context.palette;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Account header ----
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  GradientAvatar(
                    initials: initialsFrom(member?.fullName ?? '—'),
                    size: 52,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member?.fullName ?? '',
                          style: context.textStyles.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((member?.email ?? '').isNotEmpty)
                          Text(
                            member!.email,
                            style: context.textStyles.bodySmall
                                ?.copyWith(color: p.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(l.profileEditProfile),
              onTap: member == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(member: member),
                        ),
                      );
                    },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(l.settingsTitle),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: Text(l.libTitle),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ExerciseLibraryScreen()),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.help_outline, color: AppColors.accent),
              title: Text(l.helpMenuItem),
              onTap: () {
                Navigator.of(context).pop();
                // The tour is orchestrated by AppShell (it drives tab/role
                // switching); replay it via the shared launcher.
                TourLauncher.replay();
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: Text(l.settingsLogout,
                  style: const TextStyle(color: AppColors.danger)),
              onTap: () => _logout(context),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
