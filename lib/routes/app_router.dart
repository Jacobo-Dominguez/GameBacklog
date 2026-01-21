import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/backlog/backlog_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/providers/auth_provider.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Si no está autenticado y no está en login/register, redirigir a login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // Si está autenticado y está en login/register, redirigir a home
      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null; // No redirigir
    },
    routes: [
      // Rutas públicas
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Rutas privadas
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const BacklogScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Ruta: ${state.uri}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
}
