import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/messaging_controller.dart';
import 'widgets/thread_bubble.dart';

/// A one-to-one conversation with a peer (a trainer messaging a client, or a
/// trainee messaging their coach). Messages persist on the server.
class ThreadScreen extends StatefulWidget {
  const ThreadScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    this.iAmCoach = false,
  });

  final String peerId;
  final String peerName;

  /// Whether the current user is the coach in this thread (controls which
  /// bubbles sit on the right).
  final bool iAmCoach;

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<MessagingController>().load(widget.peerId));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    await context.read<MessagingController>().send(widget.peerId, text);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final messaging = context.watch<MessagingController>();
    final messages = messaging.thread(widget.peerId);

    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                reverse: true,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen, vertical: AppSpacing.md),
                children: [
                  for (final m in messages.reversed)
                    ThreadBubble(
                      message: m,
                      mine: m.fromCoach == widget.iAmCoach,
                    ),
                ],
              ),
            ),
            _Composer(controller: _input, hint: l.coachMessageHint, onSend: _send),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer(
      {required this.controller, required this.hint, required this.onSend});
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(hintText: hint, isDense: true),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Material(
            color: AppColors.ember,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSend,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.arrow_upward, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
