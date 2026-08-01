import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/arete_app.dart';
import 'data/api/api_client.dart';
import 'data/repositories/api_auth_repository.dart';
import 'data/repositories/api_profile_repository.dart';
import 'data/repositories/mock_coach_repository.dart';
import 'data/repositories/mock_progress_repository.dart';
import 'data/repositories/mock_workout_repository.dart';
import 'state/assessment_controller.dart';
import 'state/auth_controller.dart';
import 'state/coach_controller.dart';
import 'state/hydration_controller.dart';
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

  final authController = AuthController(
    authRepository,
    onAuthenticated: (user) async {
      await profileController.load();
      await profileController.applyAccount(name: user.name, email: user.email);
    },
    onSignedOut: () async => profileController.clear(),
  )..bootstrap();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authController),
        ChangeNotifierProvider(create: (_) => SessionController()),
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
        ChangeNotifierProvider(create: (_) => AssessmentController()),
        ChangeNotifierProvider(
          create: (_) => CoachController(coachRepository),
        ),
      ],
      child: const AreteApp(),
    ),
  );
}
