import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../features/welcome/welcome_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
// import '../../features/auth/reset_password_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/scan/scan_screen.dart';
import '../../features/scan/results_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../data/models/scan_model.dart';

class RouteNames {
  RouteNames._();
  static const welcome = 'welcome';
  static const signup = 'signup';
  static const login = 'login';
  static const forgotPassword = 'forgot-password';
  // static const resetPassword = 'reset-password';
  static const dashboard = 'dashboard';
  static const scan = 'scan';
  static const results = 'results';
  static const history = 'history';
  static const profile = 'profile';
}

/// Notifies GoRouter to re-evaluate redirects whenever auth status changes.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (previous, next) {
      if (previous?.status != next.status) notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isUnknown = authState.status == AuthStatus.unknown;

    final publicRoutes = ['/', '/signup', '/login', '/forgot-password'];
      final isGoingToPublic = publicRoutes.any((p) => state.matchedLocation == p);
      if (isUnknown) return null; // still checking session — don't redirect yet

      if (!isAuthenticated && !isGoingToPublic) return '/';
      if (isAuthenticated && isGoingToPublic) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: RouteNames.signup,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // GoRoute(
      //   path: '/reset-password',
      //   name: RouteNames.resetPassword,
      //   builder: (context, state) {
      //     final token = state.uri.queryParameters['token'];
      //     return ResetPasswordScreen(token: token);
      //   },
      // ),
      //Authenticated shell with persistent bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: RouteNames.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/scan',
            name: RouteNames.scan,
            builder: (context, state) => const ScanScreen(),
          ),
          GoRoute(
            path: '/history',
            name: RouteNames.history,
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      // Results screen lives outside the bottom-nav shell (full-screen flow after a scan)
      GoRoute(
        path: '/results',
        name: RouteNames.results,
        builder: (context, state) {
          final scan = state.extra as ScanModel?;
          return ResultsScreen(scan: scan);
        },
      ),
    ],
  );
});
