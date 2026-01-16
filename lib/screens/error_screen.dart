import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Screen displayed when an unrecoverable error occurs.
///
/// Provides a user-friendly error display with an error icon, message,
/// and a retry button that navigates back to the home screen. Used as
/// a fallback when the application encounters critical errors.
///
/// Example usage with navigation:
/// ```dart
/// context.go('/error', extra: {
///   'errorMessage': 'Something went wrong',
///   'stackTrace': stackTrace.toString(),
/// });
/// ```
class ErrorScreen extends StatelessWidget {
  /// Optional error message to display to the user.
  final String? errorMessage;

  /// Optional stack trace for debugging purposes (not shown to user).
  final String? stackTrace;

  const ErrorScreen({super.key, this.errorMessage, this.stackTrace});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Algo salió mal',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (errorMessage != null) ...[
                Text(
                  errorMessage!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Reintentar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
