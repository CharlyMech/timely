import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:timely/viewmodels/employee_viewmodel.dart';

/// Splash screen that handles initial app loading and employee data fetch.
///
/// This screen displays the app logo and loading indicator while initializing
/// the application by loading employee data. On success, it shows a start button
/// to navigate to the main staff interface. On error, it navigates to an error screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

/// State for [SplashScreen] that manages initialization and UI state.
class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initializeApp());
  }

  // Initialize app by loading employee data
  Future<void> _initializeApp() async {
    try {
      await ref.read(employeeViewModelProvider.notifier).loadEmployees();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        context.go(
          '/error',
          extra: {
            'errorMessage': e.toString(),
            'stackTrace': stackTrace.toString(),
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              const Spacer(),
              SvgPicture.asset(
                'assets/images/logo.svg',
                semanticsLabel: 'Timely Logo',
                height: 120,
                colorFilter: ColorFilter.mode(
                  theme.primaryColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Timely',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                'Tu aplicación de registro horario',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              if (_isLoading)
                Column(
                  spacing: 16,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.primaryColor,
                      ),
                    ),
                    Text(
                      'Cargando...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  spacing: 16,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        context.go('/staff');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Empezar',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Accede a tu registro horario',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
