import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/arete_app.dart';
import 'core/constants/enums.dart';
import 'core/notifications/notification_copy.dart';
import 'core/notifications/notification_service.dart';
import 'data/api/api_client.dart';
import 'data/repositories/api_auth_repository.dart';
import 'data/repositories/api_profile_repository.dart';
import 'data/repositories/nutrition_repository.dart';
import 'data/repositories/mock_coach_repository.dart';
import 'data/repositories/mock_progress_repository.dart';
import 'data/repositories/mock_workout_repository.dart';
import 'state/assessment_controller.dart';
import 'state/auth_controller.dart';
import 'state/coach_controller.dart';
import 'state/connect_controller.dart';
import 'state/exercise_library_controller.dart';
import 'state/help_controller.dart';
import 'state/hydration_controller.dart';
import 'state/locale_controller.dart';
import 'state/meal_schedule_controller.dart';
import 'state/messaging_controller.dart';
import 'state/my_plan_controller.dart';
import 'state/notifications_controller.dart';
import 'state/nutrition_controller.dart';
import 'state/plans_controller.dart';
import 'state/profile_controller.dart';
import 'state/progress_controller.dart';
import 'state/session_controller.dart';
import 'state/tips_controller.dart';
import 'state/trainer_controller.dart';
import 'state/workout_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Auth + profile now talk to the ARETE server (address is hard-coded and
  // obfuscated in ApiConfig). Workouts/progress/coach remain local for now.
  final apiClient = ApiClient();
  final profileRepository = ApiProfileRepository(apiClient);
  final workoutRepository = MockWorkoutRepository();
  final progressRepository = MockProgressRepository();
  final coachRepository = MockCoachRepository();
  final authRepository = ApiAuthRepository(apiClient);

  final profileController = ProfileController(profileRepository);
  final sessionController = SessionController();
  final connectController = ConnectController(apiClient);
  final myPlanController = MyPlanController(apiClient);
  final notificationsController = NotificationsController(apiClient);
  final assessmentController = AssessmentController();

  // Eating & drinking. The nutrition controller is the source of truth for the
  // water goal and today's intake; the reminder controllers read from it.
  final nutritionRepository = NutritionRepository(apiClient);
  final nutritionController = NutritionController(nutritionRepository);

  // Reminder controllers. They own their own schedules and settings, so they
  // start themselves rather than waiting for a sign-in.
  final hydrationController = HydrationController(nutritionController);
  final mealScheduleController = MealScheduleController(nutritionRepository);
  final tipsController = TipsController();

  // OS notifications fire while the app is closed, out of reach of
  // AppLocalizations — mirror the chosen language into the notification copy
  // and rebuild the schedules whenever it changes.
  final localeController = LocaleController();
  void applyNotificationLocale() {
    final code = localeController.locale?.languageCode ??
        PlatformDispatcher.instance.locale.languageCode;
    if (code == NotificationCopy.localeCode) return;
    NotificationCopy.setLocale(code);
    hydrationController.applySchedule();
    mealScheduleController.applySchedule();
    tipsController.applySchedule();
  }

  NotificationCopy.setLocale(
    localeController.locale?.languageCode ??
        PlatformDispatcher.instance.locale.languageCode,
  );
  localeController.addListener(applyNotificationLocale);

  // Tapping a water reminder opens ARETE on the "did you drink?" prompt, so a
  // glass can be logged straight from the notification.
  NotificationService.onSelect = (payload) {
    if (payload == 'hydration') hydrationController.triggerInAppPromptNow();
  };

  // Restores each controller's settings, asks for the notification permission
  // once, and (re)builds the OS schedules. Nutrition goes first so the water
  // reminders are built from the stored goal rather than the default.
  nutritionController.load().then((_) => hydrationController.init());
  mealScheduleController.init();
  tipsController.init();

  final authController = AuthController(
    authRepository,
    onAuthenticated: (user) async {
      // Every sign-in starts in trainee view; a trainer switches to coach
      // mode via the header icon. This prevents a previous trainer session's
      // role from leaking into a different (trainee-only) account.
      sessionController.setRole(UserRole.member);
      await profileController.load();
      await profileController.applyAccount(name: user.name, email: user.email);
      notificationsController.load();
      // Pull this account's goal, intake and meal schedule, then re-time the
      // reminders around them.
      await nutritionController.load();
      await mealScheduleController.reloadFromStore();
      await hydrationController.applySchedule();
    },
    onSignedOut: () async {
      sessionController.setRole(UserRole.member);
      profileController.clear();
      connectController.clear();
      myPlanController.clear();
      notificationsController.clear();
      nutritionController.clear();
      assessmentController.clearSelectedPlan();
    },
  )..bootstrap();

  // If the server reports the account was frozen, sign out immediately so the
  // member/trainer is returned to the login screen instead of seeing errors.
  apiClient.onSuspended = () => authController.signOut();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authController),
        ChangeNotifierProvider.value(value: localeController),
        ChangeNotifierProvider(create: (_) => HelpController()),
        ChangeNotifierProvider.value(value: sessionController),
        ChangeNotifierProvider.value(value: profileController),
        ChangeNotifierProvider(
          create: (_) => TrainerController(profileRepository),
        ),
        ChangeNotifierProvider.value(value: nutritionController),
        ChangeNotifierProvider.value(value: hydrationController),
        ChangeNotifierProvider.value(value: mealScheduleController),
        ChangeNotifierProvider.value(value: tipsController),
        ChangeNotifierProvider(
          create: (_) => WorkoutController(workoutRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ProgressController(progressRepository),
        ),
        ChangeNotifierProvider.value(value: assessmentController),
        ChangeNotifierProvider(
          create: (_) => CoachController(coachRepository),
        ),
        ChangeNotifierProvider.value(value: connectController),
        ChangeNotifierProvider(
          create: (_) => PlansController(apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => ExerciseLibraryController(apiClient),
        ),
        ChangeNotifierProvider.value(value: myPlanController),
        ChangeNotifierProvider.value(value: notificationsController),
        ChangeNotifierProvider(
          create: (_) => MessagingController(apiClient),
        ),
      ],
      child: const AreteApp(),
    ),
  );
}
