import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:timely/viewmodels/employee_viewmodel.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Add delay
    Future.microtask(() => _initializeApp());
  }

  Future<void> _initializeApp() async {
    try {
      await ref.read(employeeViewModelProvider.notifier).loadEmployees();

      // Wait 1 second of delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        context.go('/welcome');
      } else {
        // Do something here
        // print('❌ SplashScreen: Widget no está montado');
      }
    } catch (e, stackTrace) {
      print('❌ SplashScreen: Error al inicializar: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al inicializar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/images/logo.svg',
                  semanticsLabel: 'Timely Logo',
                  height: 100,
                  colorFilter: ColorFilter.mode(
                    theme.primaryColor,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Timely',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tu aplicación de registro horario',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 100,
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cargando...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
