import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timely/app.dart';
import 'package:timely/config/setup.dart';
import 'package:timely/config/providers.dart';
import 'package:timely/config/environment.dart';
import 'package:timely/config/firebase_options.dart';
import 'package:timely/utils/timezone_utils.dart';

/// Main entry point for the Timely application.
///
/// Initializes Flutter bindings, date formatting for Spanish locale,
/// Spanish timezone (Europe/Madrid), Firebase when flavor is firebase,
/// and shared preferences before running the app with Riverpod provider scope.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  await TimezoneUtils.initialize();

  if (Environment.isFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  /// Load preferences from config
  final prefs = await AppSetup.initializePreferences();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const App(),
    ),
  );
}
