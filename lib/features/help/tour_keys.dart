import 'package:flutter/widgets.dart';

/// Shared [GlobalKey]s that let the guided tour spotlight real widgets across
/// screens. A widget attaches the matching key; the tour measures it to cut
/// the spotlight hole. Member keys and trainer keys never coexist in the tree
/// (the two roles build different tabs), so reusing a single set is safe.
class TourKeys {
  TourKeys._();

  // Bottom-navigation destinations.
  static final navHome = GlobalKey(debugLabel: 'tour_navHome');
  static final navTrain = GlobalKey(debugLabel: 'tour_navTrain');
  static final navProgress = GlobalKey(debugLabel: 'tour_navProgress');
  static final navCoach = GlobalKey(debugLabel: 'tour_navCoach');
  static final navClients = GlobalKey(debugLabel: 'tour_navClients');
  static final navPlans = GlobalKey(debugLabel: 'tour_navPlans');
  static final navMessages = GlobalKey(debugLabel: 'tour_navMessages');
  static final navNutrition = GlobalKey(debugLabel: 'tour_navNutrition');

  // Home-screen internals.
  static final homeAccount = GlobalKey(debugLabel: 'tour_homeAccount');
  static final homeStreak = GlobalKey(debugLabel: 'tour_homeStreak');
  static final homeActivity = GlobalKey(debugLabel: 'tour_homeActivity');
  static final homeWorkout = GlobalKey(debugLabel: 'tour_homeWorkout');
}

/// A tiny hand-off so the account drawer (and anywhere else) can replay the
/// guided tour, which is orchestrated by the [AppShell] state (it owns the tab
/// switching the tour needs). The shell registers its launcher on mount.
class TourLauncher {
  TourLauncher._();

  static void Function()? _replay;

  static void register(void Function() replay) => _replay = replay;
  static void unregister() => _replay = null;

  static bool get available => _replay != null;
  static void replay() => _replay?.call();
}
