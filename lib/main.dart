import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/arete_app.dart';
import 'data/repositories/local_auth_repository.dart';
import 'data/repositories/local_profile_repository.dart';
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

  // Local-first with real on-device persistence. Each repository implements an
  // interface, so a Firebase/REST backend can replace these with no UI change.
  final profileRepository = LocalProfileRepository();
  final workoutRepository = MockWorkoutRepository();
  final progressRepository = MockProgressRepository();
  final coachRepository = MockCoachRepository();
  final authRepository = LocalAuthRepository();

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
