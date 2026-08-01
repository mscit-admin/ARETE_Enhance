import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/gradient_avatar.dart';
import '../../state/auth_controller.dart';
import '../../state/profile_controller.dart';
import 'edit_profile_screen.dart';

/// Side menu opened from the account icon in a screen header. Holds the
/// account actions — edit profile and log out.
class AccountDrawer extends StatelessWidget {
  const AccountDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    final l = AppLocalizations.of(context);
    Navigator.of(context).pop(); // close the drawer first
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
