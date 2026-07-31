import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/arete_app.dart';
import 'data/repositories/mock_profile_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'state/profile_controller.dart';
import 'state/session_controller.dart';
import 'state/trainer_controller.dart';

void main() {
  // Local-first: a mock repository stands in for the backend for now.
  // Swap MockProfileRepository for an API-backed implementation later — no UI change.
  final ProfileRepository profileRepository = MockProfileRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SessionController(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileController(profileRepository)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => TrainerController(profileRepository),
        ),
      ],
      child: const AreteApp(),
    ),
  );
}
