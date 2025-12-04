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
    // Delay para evitar modificar providers durante el build
    Future.microtask(() => _initializeApp());
  }

  /// Inicializa la aplicación: carga tema, datos, etc.
  Future<void> _initializeApp() async {
    try {
      print('🔵 SplashScreen: Iniciando carga de empleados...');

      // 1. Cargar empleados y sus registros
      await ref.read(employeeViewModelProvider.notifier).loadEmployees();

      print('✅ SplashScreen: Empleados cargados correctamente');

      // 2. Esperar mínimo 2 segundos para mostrar el splash
      await Future.delayed(const Duration(seconds: 2));

      print('🔵 SplashScreen: Navegando a /welcome');

      // 3. Navegar a la pantalla de bienvenida
      if (mounted) {
        context.go('/welcome');
        print('✅ SplashScreen: Navegación completada');
      } else {
        print('❌ SplashScreen: Widget no está montado');
      }
    } catch (e, stackTrace) {
      // En caso de error, mostrar un mensaje
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
                // Logo SVG
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
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
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
