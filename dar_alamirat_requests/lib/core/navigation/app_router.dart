import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'package:dar_alamirat_requests/features/dashboard/presentation/pages/request_details_page.dart';
import 'package:dar_alamirat_requests/features/auth/presentation/pages/login_page.dart';
import 'package:dar_alamirat_requests/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:dar_alamirat_requests/features/splash/presentation/pages/splash_screen.dart';
import 'package:dar_alamirat_requests/features/splash/presentation/pages/maintenance_screen.dart';
import 'package:dar_alamirat_requests/features/splash/presentation/pages/update_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final loggingIn = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/splash';
      final isMaintenance = state.matchedLocation == '/maintenance';
      final isUpdate = state.matchedLocation == '/update';

      if (isSplash || isMaintenance || isUpdate) return null;

      if (user == null) {
        return loggingIn ? null : '/login';
      }

      if (loggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/maintenance',
        builder: (context, state) {
          final message = state.extra as String?;
          return MaintenanceScreen(message: message);
        },
      ),
      GoRoute(
        path: '/update',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return UpdateScreen(
            storeUrl: extra['storeUrl'] as String,
            forceUpdate: extra['forceUpdate'] as bool,
          );
        },
      ),
      GoRoute(
        path: '/request-details',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return RequestDetailsPage(
            requestId: extra['requestId'] as String,
            type: extra['type'] as String,
            currentUser: extra['currentUser'] as Profile,
          );
        },
      ),
    ],
  );
}
