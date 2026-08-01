import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/gradient_avatar.dart';
import '../../state/connect_controller.dart';
import '../coach/thread_screen.dart';

/// Trainer-side Messages tab: pick a client to open the conversation.
class TrainerMessagesScreen extends StatefulWidget {
  const TrainerMessagesScreen({super.key});

  @override
  State<TrainerMessagesScreen> createState() => _TrainerMessagesScreenState();
}

class _TrainerMessagesScreenState extends State<TrainerMessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<ConnectController>().loadClients());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final clients = context.watch<ConnectController>().clients;
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: Text(l.navMessages)),
      body: SafeArea(
        child: clients.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  child: Text(l.messagesNoClients,
                      textAlign: TextAlign.center,
                      style: context.textStyles.bodyMedium
                          ?.copyWith(color: p.muted)),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
                  Text(l.messagesPickClient,
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: p.muted)),
                  const SizedBox(height: AppSpacing.md),
                  for (final c in clients) ...[
                    _ClientRow(
                      name: (c['full_name'] as String?) ?? 'Client',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ThreadScreen(
                            peerId: c['id'] as String,
                            peerName: (c['full_name'] as String?) ?? 'Client',
                            iAmCoach: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({required this.name, required this.onTap});
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          GradientAvatar(initials: initialsFrom(name), size: 42),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(name, style: context.textStyles.titleMedium),
          ),
          Icon(Icons.chevron_right, color: p.muted),
        ],
      ),
    );
  }
}
