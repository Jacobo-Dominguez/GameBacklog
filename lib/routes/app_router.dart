import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/backlog/backlog_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/game_detail/game_detail_screen.dart';
import '../presentation/screens/api_test/api_test_screen.dart';
import '../presentation/screens/search/search_screen.dart';
import '../presentation/screens/journal/journal_screen.dart';
import '../presentation/screens/profile/edit_profile_screen.dart';
import '../presentation/screens/profile/user_reviews_screen.dart';
import '../presentation/screens/collections/collections_screen.dart';
import '../presentation/screens/collections/collection_detail_screen.dart';
import '../presentation/screens/discovery/discovery_screen.dart';
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
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/user-reviews',
        name: 'user-reviews',
        builder: (context, state) => const UserReviewsScreen(),
      ),
      GoRoute(
        path: '/game/:id',
        name: 'game-detail',
        builder: (context, state) {
          final gameId = state.pathParameters['id']!;
          return GameDetailScreen(gameId: gameId);
        },
      ),
      GoRoute(
        path: '/api-test',
        name: 'api-test',
        builder: (context, state) => const ApiTestScreen(),
      ),
      // ✅ NUEVA RUTA DE BÚSQUEDA (SIN const)
      GoRoute(
  path: '/search',
  name: 'search',
  builder: (context, state) => const SearchScreen(),
),
GoRoute(
  path: '/journal',
  name: 'journal',
  builder: (context, state) => const JournalScreen(),
),
GoRoute(
  path: '/collections',
  name: 'collections',
  builder: (context, state) => const CollectionsScreen(),
),
GoRoute(
  path: '/collections/:id',
  name: 'collection-detail',
  builder: (context, state) {
    final listId = state.pathParameters['id']!;
    return CollectionDetailScreen(listId: listId);
  },
),
GoRoute(
  path: '/discovery',
  name: 'discovery',
  builder: (context, state) => const DiscoveryScreen(),
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