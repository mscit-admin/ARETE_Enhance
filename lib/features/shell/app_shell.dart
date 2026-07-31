import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../profile/member_profile_screen.dart';
import '../profile/trainer_home_screen.dart';
import '../placeholder/coming_soon_screen.dart';
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

    final tabs = isTrainer ? _trainerTabs : _memberTabs;
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

  List<_TabDef> get _memberTabs => const [
        _TabDef(
          label: 'Home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          screen: MemberProfileScreen(),
        ),
        _TabDef(
          label: 'Train',
          icon: Icons.fitness_center_outlined,
          activeIcon: Icons.fitness_center,
          screen: ComingSoonScreen(
            title: 'Train',
            moduleName: 'Workout Execution',
            description:
                'Today\'s session, set-by-set logging, rest timer, form videos '
                'and live PR detection — the daily driver, coming next.',
            icon: Icons.fitness_center,
          ),
        ),
        _TabDef(
          label: 'Progress',
          icon: Icons.insights_outlined,
          activeIcon: Icons.insights_rounded,
          screen: ComingSoonScreen(
            title: 'Progress',
            moduleName: 'Progress Tracking',
            description:
                'Weight trend, training volume, personal records, measurements '
                'and progress photos.',
            icon: Icons.insights_rounded,
          ),
        ),
        _TabDef(
          label: 'Coach',
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
          screen: ComingSoonScreen(
            title: 'Coach',
            moduleName: 'Trainer Management',
            description:
                'Your assigned coach, in-app messaging, plan hand-off and '
                'session booking.',
            icon: Icons.chat_bubble,
          ),
        ),
      ];

  List<_TabDef> get _trainerTabs => const [
        _TabDef(
          label: 'Clients',
          icon: Icons.groups_outlined,
          activeIcon: Icons.groups_rounded,
          screen: TrainerHomeScreen(),
        ),
        _TabDef(
          label: 'Plans',
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment,
          screen: ComingSoonScreen(
            title: 'Plans',
            moduleName: 'Plan Assignment',
            description:
                'Build and assign training programs to your clients, review '
                'their logs and adjust targets.',
            icon: Icons.assignment,
          ),
        ),
        _TabDef(
          label: 'Messages',
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
          screen: ComingSoonScreen(
            title: 'Messages',
            moduleName: 'Client Messaging',
            description: 'One-on-one chat with each of your clients.',
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
