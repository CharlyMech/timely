import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/config/setup.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final brightness = AppSetup.getSystemBrightness();
      ref.read(themeViewModelProvider.notifier).initialize(brightness);
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    ref.watch(themeViewModelProvider);
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
