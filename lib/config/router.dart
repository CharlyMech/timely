import 'package:go_router/go_router.dart';
import 'package:timely/screens/splash_screen.dart';
import 'package:timely/screens/welcome_screen.dart';
import 'package:timely/screens/staff_screen.dart';
import 'package:timely/screens/time_registration_detail_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (context, state) => const WelcomeScreen(),
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
  ],
);
