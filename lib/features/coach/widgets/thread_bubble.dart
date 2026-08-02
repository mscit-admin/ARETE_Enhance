import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/thread_message.dart';
import '../../../l10n/app_localizations.dart';

/// Renders one server-backed message. [minePredicate] decides which side a
/// message sits on: the trainee sees coach messages on the left; the trainer
/// sees their own (from_coach) messages on the right.
class ThreadBubble extends StatelessWidget {
  const ThreadBubble({
    super.key,
    required this.message,
    required this.mine,
    this.onViewPlan,
  });

  final ThreadMessage message;
  final bool mine;
  final VoidCallback? onViewPlan;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);

    if (message.isPlanCard) {
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
                          const Icon(Icons.assignment, color: AppColors.accent),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.chatNewProgram,
                              style: context.textStyles.bodySmall
                                  ?.copyWith(color: p.muted)),
                          Text(
                              message.body.isEmpty
                                  ? l.chatTrainingPlan
                                  : message.body,
                              style: context.textStyles.titleMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (onViewPlan != null) ...[
                Divider(height: 1, color: p.line),
                InkWell(
                  onTap: onViewPlan,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(l.chatViewPlan,
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.76),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppColors.accent : p.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 4),
            bottomRight: Radius.circular(mine ? 4 : 14),
          ),
          border: mine ? null : Border.all(color: p.line),
        ),
        child: Text(
          message.body,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: mine ? AppColors.onAccent : p.text,
          ),
        ),
      ),
    );
  }
}
