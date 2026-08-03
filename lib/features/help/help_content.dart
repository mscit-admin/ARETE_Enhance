import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// One page of the in-app guide: an icon tile plus a title and explanation.
class HelpStep {
  const HelpStep({
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String body;
}

/// Builds the guide pages for the active role. A trainer account gets the
/// member pages first, then a coach-tools section covering the trainer
/// screens, so the assistant "moves on" to explain them too.
List<HelpStep> helpStepsFor(AppLocalizations l, {required bool isTrainer}) {
  final steps = <HelpStep>[
    HelpStep(
      icon: Icons.waving_hand_rounded,
      tint: AppColors.accent,
      title: l.helpWelcomeTitle,
      body: l.helpWelcomeBody,
    ),
    HelpStep(
      icon: Icons.home_rounded,
      tint: AppColors.accent,
      title: l.helpHomeTitle,
      body: l.helpHomeBody,
    ),
    HelpStep(
      icon: Icons.fitness_center,
      tint: AppColors.move,
      title: l.helpTrainTitle,
      body: l.helpTrainBody,
    ),
    HelpStep(
      icon: Icons.insights_rounded,
      tint: AppColors.steps,
      title: l.helpProgressTitle,
      body: l.helpProgressBody,
    ),
    HelpStep(
      icon: Icons.chat_bubble_rounded,
      tint: AppColors.water,
      title: l.helpCoachTitle,
      body: l.helpCoachBody,
    ),
    HelpStep(
      icon: Icons.account_circle_rounded,
      tint: AppColors.teal,
      title: l.helpProfileTitle,
      body: l.helpProfileBody,
    ),
    HelpStep(
      icon: Icons.translate_rounded,
      tint: AppColors.accent,
      title: l.helpLanguageTitle,
      body: l.helpLanguageBody,
    ),
  ];

  if (isTrainer) {
    steps.addAll([
      HelpStep(
        icon: Icons.sports_rounded,
        tint: AppColors.accent,
        title: l.helpTrainerIntroTitle,
        body: l.helpTrainerIntroBody,
      ),
      HelpStep(
        icon: Icons.groups_rounded,
        tint: AppColors.teal,
        title: l.helpClientsTitle,
        body: l.helpClientsBody,
      ),
      HelpStep(
        icon: Icons.assignment,
        tint: AppColors.move,
        title: l.helpPlansTitle,
        body: l.helpPlansBody,
      ),
      HelpStep(
        icon: Icons.chat_bubble_rounded,
        tint: AppColors.water,
        title: l.helpMessagesTitle,
        body: l.helpMessagesBody,
      ),
      HelpStep(
        icon: Icons.swap_horiz_rounded,
        tint: AppColors.steps,
        title: l.helpRoleSwitchTitle,
        body: l.helpRoleSwitchBody,
      ),
    ]);
  }

  return steps;
}
