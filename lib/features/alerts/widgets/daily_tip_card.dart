import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/tips_controller.dart';
import '../alerts_screen.dart';

/// The tip of the day on the home screen. Dismissing it hides it until
/// tomorrow's tip; tapping it opens the alerts settings.
class DailyTipCard extends StatelessWidget {
  const DailyTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tips = context.watch<TipsController>();
    final l = AppLocalizations.of(context);
    final p = context.palette;

    if (!tips.showCard) return const SizedBox.shrink();

    // Owns its bottom spacing so the home screen collapses cleanly when the
    // card is dismissed.
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(l.tipOfDayTitle,
                    style: context.textStyles.titleMedium),
              ),
              IconButton(
                tooltip: l.alertsTitle,
                icon: Icon(Icons.tune, size: 18, color: p.muted),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AlertsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(tips.tipOfDayText, style: context.textStyles.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => context.read<TipsController>().dismissToday(),
              child: Text(l.tipDismiss),
            ),
          ),
        ],
      ),
    );
  }
}
