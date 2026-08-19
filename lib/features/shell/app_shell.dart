import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../help/guided_tour.dart';
import '../help/tour_keys.dart';
import '../profile/account_drawer.dart';
import '../profile/member_profile_screen.dart';
import '../profile/trainer_home_screen.dart';
import 'root_scaffold_key.dart';
import '../assessment/assessment_entry_screen.dart';
import '../trainer/plans_screen.dart';
import '../trainer/trainer_messages_screen.dart';
import '../workout/workout_home_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../progress/progress_screen.dart';
import '../coach/coach_screen.dart';
import '../../state/auth_controller.dart';
import '../../state/connect_controller.dart';
import '../../state/help_controller.dart';
import '../../state/messaging_controller.dart';
import '../../state/notifications_controller.dart';
import '../../state/my_plan_controller.dart';
import '../../state/nutrition_controller.dart';
import '../../state/plans_controller.dart';
import '../../state/profile_controller.dart';
import '../../state/progress_controller.dart';
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
  bool _introHandled = false;
  bool _tourRunning = false;

  @override
  void initState() {
    super.initState();
    // Let the account drawer replay the guided tour on demand.
    TourLauncher.register(() => _runTour());
  }

  @override
  void dispose() {
    TourLauncher.unregister();
    super.dispose();
  }

  /// Switch the visible tab (used both by taps and by the guided tour).
  void _goTab(int i) {
    final isTrainer = context.read<SessionController>().isTrainer;
    setState(() => _index = i);
    _refreshTab(i, isTrainer);
  }

  /// Auto-start the walkthrough the first time the app opens, once the
  /// profile has loaded so the Home targets can be measured.
  void _maybeAutoStartTour() {
    if (_introHandled) return;
    final help = context.read<HelpController>();
    final ready = context.read<ProfileController>().status == LoadStatus.ready;
    if (!help.shouldAutoShow || !ready) return;
    _introHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _runTour();
    });
  }

  /// Build and launch the spotlight tour for the current account.
  void _runTour() {
    if (_tourRunning) return;
    _tourRunning = true;
    final l = AppLocalizations.of(context);
    final isTrainerAccount =
        context.read<AuthController>().user?.isTrainer ?? false;

    GuidedTour(
      context,
      _buildSteps(l, isTrainerAccount),
      onFinished: () {
        _tourRunning = false;
        context.read<HelpController>().markIntroSeen();
        // Return trainers to the trainee Home view where the tour began.
        context.read<SessionController>().setRole(UserRole.member);
        _goTab(0);
      },
    ).start();
  }

  List<TourStep> _buildSteps(AppLocalizations l, bool isTrainerAccount) {
    Future<void> member() async {
      context.read<SessionController>().setRole(UserRole.member);
      _goTab(0);
    }

    final steps = <TourStep>[
      TourStep(
        title: l.helpWelcomeTitle,
        body: l.helpWelcomeBody,
        before: member,
      ),
      TourStep(
        target: TourKeys.navHome,
        circle: true,
        title: l.helpHomeTitle,
        body: l.helpHomeBody,
        before: member,
      ),
      TourStep(
        target: TourKeys.homeAccount,
        circle: true,
        title: l.tourAccountTitle,
        body: l.tourAccountBody,
      ),
      TourStep(
        target: TourKeys.homeStreak,
        title: l.tourStreakTitle,
        body: l.tourStreakBody,
      ),
      TourStep(
        target: TourKeys.homeActivity,
        title: l.tourActivityTitle,
        body: l.tourActivityBody,
      ),
      TourStep(
        target: TourKeys.homeWorkout,
        title: l.tourWorkoutTitle,
        body: l.tourWorkoutBody,
      ),
      TourStep(
        target: TourKeys.navTrain,
        circle: true,
        title: l.helpTrainTitle,
        body: l.helpTrainBody,
        before: () async => _goTab(1),
      ),
      TourStep(
        target: TourKeys.navNutrition,
        circle: true,
        title: l.helpNutritionTitle,
        body: l.helpNutritionBody,
        before: () async => _goTab(2),
      ),
      TourStep(
        target: TourKeys.navCoach,
        circle: true,
        title: l.helpCoachTitle,
        body: l.helpCoachBody,
        before: () async => _goTab(3),
      ),
      TourStep(
        target: TourKeys.navAssessment,
        circle: true,
        title: l.helpAssessmentTitle,
        body: l.helpAssessmentBody,
        before: () async => _goTab(4),
      ),
    ];

    if (isTrainerAccount) {
      Future<void> coach(int tab) async {
        context.read<SessionController>().setRole(UserRole.trainer);
        _goTab(tab);
      }

      steps.addAll([
        TourStep(
          title: l.helpTrainerIntroTitle,
          body: l.helpTrainerIntroBody,
          before: () => coach(0),
        ),
        TourStep(
          target: TourKeys.navClients,
          circle: true,
          title: l.helpClientsTitle,
          body: l.helpClientsBody,
          before: () => coach(0),
        ),
        TourStep(
          target: TourKeys.navPlans,
          circle: true,
          title: l.helpPlansTitle,
          body: l.helpPlansBody,
          before: () => coach(1),
        ),
        TourStep(
          target: TourKeys.navMessages,
          circle: true,
          title: l.helpMessagesTitle,
          body: l.helpMessagesBody,
          before: () => coach(2),
        ),
        TourStep(
          target: TourKeys.navProgress,
          circle: true,
          title: l.helpProgressTitle,
          body: l.helpProgressBody,
          before: () => coach(3),
        ),
      ]);
    }
    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final isTrainer = session.role == UserRole.trainer;
    final l = AppLocalizations.of(context);

    // Kick off the first-run guide once the flag + profile have loaded.
    context.watch<HelpController>();
    context.watch<ProfileController>();
    _maybeAutoStartTour();

    final tabs = isTrainer ? _trainerTabs(l) : _memberTabs(l);
    // Guard against an out-of-range index when the role (and tab count) changes.
    final safeIndex = _index.clamp(0, tabs.length - 1).toInt();
    final p = context.palette;

    // Layout: destination 0 is the raised centre button (Home / Clients);
    // the rest sit to the left and right of the notch.
    //   Member  → left: Assessment, Coach · centre: Home    · right: Nutrition, Train
    //   Trainer → left: Messages          · centre: Clients · right: Plans, Progress
    const centreIndex = 0;
    final leftIndices = isTrainer ? const [2] : const [4, 3];
    final rightIndices = isTrainer ? const [1, 3] : const [2, 1];

    void select(int i) => _goTab(i);

    return Scaffold(
      key: rootScaffoldKey,
      endDrawer: const AccountDrawer(),
      body: IndexedStack(
        index: safeIndex,
        children: [for (final t in tabs) t.screen],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        key: tabs[centreIndex].navKey,
        height: 62,
        width: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.45),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => select(centreIndex),
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          elevation: 0,
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
                      key: tabs[i].navKey,
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
                      key: tabs[i].navKey,
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
    if (i == 0) context.read<NotificationsController>().load();
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
      } else if (i == 3) {
        context.read<ProgressController>().load();
      }
    } else {
      final profile = context.read<ProfileController>();
      if (i == 0) {
        profile.load();
      } else if (i == 2) {
        context.read<NutritionController>().load();
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
          navKey: TourKeys.navHome,
        ),
        _TabDef(
          label: l.navTrain,
          icon: Icons.fitness_center_outlined,
          activeIcon: Icons.fitness_center,
          screen: const WorkoutHomeScreen(),
          navKey: TourKeys.navTrain,
        ),
        _TabDef(
          label: l.navNutrition,
          icon: Icons.restaurant_menu_outlined,
          activeIcon: Icons.restaurant_menu,
          screen: const NutritionScreen(),
          navKey: TourKeys.navNutrition,
        ),
        _TabDef(
          label: l.navCoach,
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
          screen: const CoachScreen(),
          navKey: TourKeys.navCoach,
        ),
        _TabDef(
          label: l.navAssessment,
          icon: Icons.assignment_turned_in_outlined,
          activeIcon: Icons.assignment_turned_in,
          screen: const AssessmentEntryScreen(),
          navKey: TourKeys.navAssessment,
        ),
      ];

  List<_TabDef> _trainerTabs(AppLocalizations l) => [
        _TabDef(
          label: l.navClients,
          icon: Icons.groups_outlined,
          activeIcon: Icons.groups_rounded,
          screen: const TrainerHomeScreen(),
          navKey: TourKeys.navClients,
        ),
        _TabDef(
          label: l.navPlans,
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment,
          screen: const PlansScreen(),
          navKey: TourKeys.navPlans,
        ),
        _TabDef(
          label: l.navMessages,
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
          screen: const TrainerMessagesScreen(),
          navKey: TourKeys.navMessages,
        ),
        _TabDef(
          label: l.navProgress,
          icon: Icons.insights_outlined,
          activeIcon: Icons.insights_rounded,
          screen: const ProgressScreen(),
          navKey: TourKeys.navProgress,
        ),
      ];
}

class _TabDef {
  const _TabDef({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.screen,
    required this.navKey,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;

  /// Key on this destination's bottom-bar button (or the centre FAB) so the
  /// guided tour can spotlight it.
  final GlobalKey navKey;
}

/// One tappable destination in the notched bottom bar (icon + label).
class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
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
