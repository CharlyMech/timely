import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timely/app.dart';
import 'package:timely/config/setup.dart';
import 'package:timely/config/providers.dart';
import 'package:timely/config/environment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log de configuración
  AppSetup.logConfiguration();

  // Inicializar Firebase solo en producción
  if (Environment.isProd) {
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Inicializar SharedPreferences
  final prefs = await AppSetup.initializePreferences();

  // Iniciar la app
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const App(),
    ),
  );
}
