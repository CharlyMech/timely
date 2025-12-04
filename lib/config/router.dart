import 'package:go_router/go_router.dart';
import 'package:timely/screens/splash_screen.dart';
import 'package:timely/screens/staff_screen.dart';
import 'package:timely/screens/time_registration_detail_screen.dart';
import 'package:timely/screens/error_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/staff',
      name: 'staff',
      builder: (context, state) => const StaffScreen(),
    ),
    GoRoute(
      path: '/employee/:id',
      name: 'employee-detail',
      builder: (context, state) {
        final employeeId = state.pathParameters['id']!;
        return TimeRegistrationDetailScreen(employeeId: employeeId);
      },
    ),
    GoRoute(
      path: '/error',
      name: 'error',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ErrorScreen(
          errorMessage: extra?['errorMessage'] as String?,
          stackTrace: extra?['stackTrace'] as String?,
        );
      },
    ),
  ],
);
