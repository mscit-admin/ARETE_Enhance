import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/arete_app.dart';
import 'data/repositories/mock_profile_repository.dart';
import 'data/repositories/mock_workout_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/workout_repository.dart';
import 'state/hydration_controller.dart';
import 'state/profile_controller.dart';
import 'state/session_controller.dart';
import 'state/trainer_controller.dart';
import 'state/workout_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Local-first: a mock repository stands in for the backend for now.
  // Swap MockProfileRepository for an API-backed implementation later — no UI change.
  final ProfileRepository profileRepository = MockProfileRepository();
  final WorkoutRepository workoutRepository = MockWorkoutRepository();
  final profileController = ProfileController(profileRepository)..load();

  runApp(
    MultiProvider(
      providers: [
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
      ],
      child: const AreteApp(),
    ),
  );
}
