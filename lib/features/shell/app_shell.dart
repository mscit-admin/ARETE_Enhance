import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../profile/account_drawer.dart';
import '../profile/member_profile_screen.dart';
import '../profile/trainer_home_screen.dart';
import 'root_scaffold_key.dart';
import '../trainer/plans_screen.dart';
import '../trainer/trainer_messages_screen.dart';
import '../workout/workout_home_screen.dart';
import '../progress/progress_screen.dart';
import '../coach/coach_screen.dart';
import '../../state/connect_controller.dart';
import '../../state/messaging_controller.dart';
import '../../state/my_plan_controller.dart';
import '../../state/plans_controller.dart';
import '../../state/profile_controller.dart';
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
    final p = context.palette;

    // Layout: destination 0 is the raised centre button (Home / Clients);
    // the rest sit to the left and right of the notch.
    //   Member  → left: Coach        · centre: Home    · right: Train, Progress
    //   Trainer → left: Messages     · centre: Clients · right: Plans
    const centreIndex = 0;
    final leftIndices = isTrainer ? const [2] : const [3];
    final rightIndices = isTrainer ? const [1] : const [1, 2];

    void select(int i) {
      setState(() => _index = i);
      _refreshTab(i, isTrainer);
    }

    return Scaffold(
      key: rootScaffoldKey,
      endDrawer: const AccountDrawer(),
      body: IndexedStack(
        index: safeIndex,
        children: [for (final t in tabs) t.screen],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 62,
        width: 62,
        child: FloatingActionButton(
          onPressed: () => select(centreIndex),
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          elevation: 3,
          shape: const CircleBorder(),
          child: Icon(tabs[centreIndex].activeIcon,
              color: AppColors.onAccent, size: 28),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: p.surface,
        elevation: 8,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 64,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final i in leftIndices)
                    _NavItem(
                      tab: tabs[i],
                      selected: safeIndex == i,
                      onTap: () => select(i),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 64), // room for the docked Home button
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final i in rightIndices)
                    _NavItem(
                      tab: tabs[i],
                      selected: safeIndex == i,
                      onTap: () => select(i),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pull fresh data for the tab the user just opened, so newly-linked clients,
  /// assigned plans and messages appear without a re-login.
  void _refreshTab(int i, bool isTrainer) {
    if (isTrainer) {
      final connect = context.read<ConnectController>();
      if (i == 0) {
        connect.loadClients();
        connect.loadTrainerCode();
      } else if (i == 1) {
        context.read<PlansController>().load();
        connect.loadClients();
      } else if (i == 2) {
        connect.loadClients();
      }
    } else {
      final profile = context.read<ProfileController>();
      if (i == 0) {
        profile.load();
      } else if (i == 3) {
        profile.load();
        context.read<MyPlanController>().load();
        final coach = profile.assignedTrainer;
        if (coach != null) {
          context.read<MessagingController>().load(coach.id);
        }
      }
    }
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
          screen: const PlansScreen(),
        ),
        _TabDef(
          label: l.navMessages,
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
          screen: const TrainerMessagesScreen(),
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

/// One tappable destination in the notched bottom bar (icon + label).
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _TabDef tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : context.palette.muted;
    return InkResponse(
      onTap: onTap,
      radius: 36,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? tab.activeIcon : tab.icon, color: color, size: 24),
          const SizedBox(height: 3),
          Text(
            tab.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
