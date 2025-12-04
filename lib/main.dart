import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timely/app.dart';
import 'package:timely/config/setup.dart';
import 'package:timely/config/providers.dart';
import 'package:timely/config/environment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppSetup.logConfiguration();

  if (Environment.isProd) {
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  final prefs = await AppSetup.initializePreferences();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const App(),
    ),
  );
}
