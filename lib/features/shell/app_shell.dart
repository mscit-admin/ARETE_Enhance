import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../l10n/app_localizations.dart';
import '../profile/member_profile_screen.dart';
import '../profile/trainer_home_screen.dart';
import '../placeholder/coming_soon_screen.dart';
import '../workout/workout_home_screen.dart';
import '../progress/progress_screen.dart';
import '../coach/coach_screen.dart';
import '../../state/session_controller.dart';

/// Root scaffold with bottom navigation. The tab set adapts to the active
/// role: members get Home/Train/Progress/Coach; trainers get a Clients-first
/// layout. Only the profile-related tabs are built in Phase 1 slice one; the
/// rest are clearly-labelled "coming next" placeholders.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final isTrainer = session.role == UserRole.trainer;
    final l = AppLocalizations.of(context);

    final tabs = isTrainer ? _trainerTabs(l) : _memberTabs(l);
    // Guard against an out-of-range index when the role (and tab count) changes.
    final safeIndex = _index.clamp(0, tabs.length - 1).toInt();

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: [for (final t in tabs) t.screen],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (i) => setState(() => _index = i),
        items: [
          for (final t in tabs)
            BottomNavigationBarItem(
              icon: Icon(t.icon),
              activeIcon: Icon(t.activeIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }

  List<_TabDef> _memberTabs(AppLocalizations l) => [
        _TabDef(
          label: l.navHome,
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          screen: const MemberProfileScreen(),
        ),
        _TabDef(
          label: l.navTrain,
          icon: Icons.fitness_center_outlined,
          activeIcon: Icons.fitness_center,
          screen: const WorkoutHomeScreen(),
        ),
        _TabDef(
          label: l.navProgress,
          icon: Icons.insights_outlined,
          activeIcon: Icons.insights_rounded,
          screen: const ProgressScreen(),
        ),
        _TabDef(
          label: l.navCoach,
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
          screen: const CoachScreen(),
        ),
      ];

  List<_TabDef> _trainerTabs(AppLocalizations l) => [
        _TabDef(
          label: l.navClients,
          icon: Icons.groups_outlined,
          activeIcon: Icons.groups_rounded,
          screen: const TrainerHomeScreen(),
        ),
        _TabDef(
          label: l.navPlans,
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment,
          screen: ComingSoonScreen(
            title: l.navPlans,
            moduleName: l.comingPlansModule,
            description: l.comingPlansDesc,
            icon: Icons.assignment,
          ),
        ),
        _TabDef(
          label: l.navMessages,
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
          screen: ComingSoonScreen(
            title: l.navMessages,
            moduleName: l.comingMessagesModule,
            description: l.comingMessagesDesc,
            icon: Icons.chat_bubble,
          ),
        ),
      ];
}

class _TabDef {
  const _TabDef({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;
}
