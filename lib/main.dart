import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/arete_app.dart';
import 'core/constants/enums.dart';
import 'data/api/api_client.dart';
import 'data/repositories/api_auth_repository.dart';
import 'data/repositories/api_profile_repository.dart';
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
import 'state/messaging_controller.dart';
import 'state/my_plan_controller.dart';
import 'state/plans_controller.dart';
import 'state/profile_controller.dart';
import 'state/progress_controller.dart';
import 'state/session_controller.dart';
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
  final assessmentController = AssessmentController();

  final authController = AuthController(
    authRepository,
    onAuthenticated: (user) async {
      // Every sign-in starts in trainee view; a trainer switches to coach
      // mode via the header icon. This prevents a previous trainer session's
      // role from leaking into a different (trainee-only) account.
      sessionController.setRole(UserRole.member);
      await profileController.load();
      await profileController.applyAccount(name: user.name, email: user.email);
    },
    onSignedOut: () async {
      sessionController.setRole(UserRole.member);
      profileController.clear();
      connectController.clear();
      myPlanController.clear();
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
        ChangeNotifierProvider(create: (_) => LocaleController()),
        ChangeNotifierProvider(create: (_) => HelpController()),
        ChangeNotifierProvider.value(value: sessionController),
        ChangeNotifierProvider.value(value: profileController),
        ChangeNotifierProvider(
          create: (_) => TrainerController(profileRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => HydrationController(profileController)..init(),
        ),
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
        ChangeNotifierProvider(
          create: (_) => MessagingController(apiClient),
        ),
      ],
      child: const AreteApp(),
    ),
  );
}
