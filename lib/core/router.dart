import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/providers.dart';

import '../presentation/screens/login_screen.dart';
import '../presentation/screens/dashboard_screen.dart';

import '../presentation/screens/project_details_screen.dart';
import '../presentation/screens/task_details_screen.dart';

import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/register_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      
      return authState.when(
        data: (user) {
          if (user == null && !isLoggingIn && !isRegistering) return '/login';
          if (user != null && (isLoggingIn || isRegistering)) return '/dashboard';
          if (user != null && state.matchedLocation == '/') return '/dashboard';
          return null;
        },
        loading: () => null,
        error: (_, __) => '/login',
      );
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/project/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProjectDetailsScreen(projectId: id);
        },
      ),
      GoRoute(
        path: '/task/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TaskDetailsScreen(taskId: id);
        },
      ),
    ],
  );
});
