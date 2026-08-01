import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/coach_chat.dart';
import '../../../l10n/app_localizations.dart';

/// Renders one chat message: coach on the left, member on the right, with
/// special cards for assigned plans and booked sessions.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    switch (message.kind) {
      case MessageKind.planCard:
        return _PlanCard(message: message);
      case MessageKind.sessionConfirmed:
        return _SystemNote(text: l.chatSessionBookedNote);
      case MessageKind.text:
        return _TextBubble(message: message);
    }
  }
}

class _TextBubble extends StatelessWidget {
  const _TextBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fromCoach = message.fromCoach;
    return Align(
      alignment: fromCoach ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.76),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: fromCoach ? p.surface : AppColors.ember,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(fromCoach ? 4 : 14),
            bottomRight: Radius.circular(fromCoach ? 14 : 4),
          ),
          border: fromCoach ? Border.all(color: p.line) : null,
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: fromCoach ? p.text : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: p.emberSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.assignment, color: AppColors.ember),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.chatNewProgram,
                            style: context.textStyles.bodySmall
                                ?.copyWith(color: p.muted)),
                        Text(message.planName ?? l.chatTrainingPlan,
                            style: context.textStyles.titleMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: p.line),
            InkWell(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(l.chatOpeningPlan(
                        message.planName ?? l.chatTrainingPlan))),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(l.chatViewPlan,
                      style: TextStyle(
                          color: AppColors.ember,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemNote extends StatelessWidget {
  const _SystemNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: p.surfaceAlt,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Text(text,
            style: context.textStyles.bodySmall?.copyWith(color: p.muted)),
      ),
    );
  }
}
