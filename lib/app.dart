import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/config/setup.dart';
import 'package:timely/config/theme.dart';
import 'package:timely/viewmodels/theme_viewmodel.dart';
import 'package:timely/config/router.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    // Inicializar el tema cuando la app arranca
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final brightness = AppSetup.getSystemBrightness();
      ref.read(themeViewModelProvider.notifier).initialize(brightness);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Observar el estado del tema
    final themeState = ref.watch(themeViewModelProvider);
    final brightness = MediaQuery.platformBrightnessOf(context);

    // Obtener el ThemeData según el tema actual
    final themeData = ref
        .read(themeViewModelProvider.notifier)
        .getThemeData(brightness);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Timely',
      theme: themeData,
      routerConfig: router,
    );
  }
}
