import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/app_notification.dart';
import '../../l10n/app_localizations.dart';
import '../../state/notifications_controller.dart';

/// The notifications centre. Opening it refreshes the list and clears the
/// unread badge.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final c = context.read<NotificationsController>();
      await c.load();
      await c.markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final items = context.watch<NotificationsController>().items;

    return Scaffold(
      appBar: AppBar(title: Text(l.notifTitle)),
      body: SafeArea(
        child: items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  child: Text(l.notifEmpty,
                      textAlign: TextAlign.center,
                      style: context.textStyles.bodyMedium
                          ?.copyWith(color: p.muted)),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.screen),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _NotificationTile(n: items[i]),
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.n});
  final AppNotification n;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final (icon, heading) = switch (n.type) {
      'plan_assigned' => (Icons.assignment, l.notifPlanAssigned),
      'session_done' => (Icons.check_circle, l.notifSessionDone),
      _ => (Icons.notifications, n.title),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: n.read ? p.surface : AppColors.limeTintBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: n.read ? p.line : AppColors.limeTintBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(heading, style: context.textStyles.titleMedium),
                if (n.title.isNotEmpty)
                  Text(n.title,
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: p.muted)),
              ],
            ),
          ),
          if (n.createdAt != null)
            Text(_ago(n.createdAt!),
                style: context.textStyles.bodySmall?.copyWith(color: p.muted)),
        ],
      ),
    );
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}
