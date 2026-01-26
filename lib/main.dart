import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/database_helper.dart';
import 'data/datasources/user_local_datasource_impl.dart';
import 'data/datasources/session_local_datasource.dart';
import 'data/datasources/game_local_datasource_impl.dart';
import 'data/datasources/game_backlog_local_datasource_impl.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/backlog_provider.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar dependencias
  final dbHelper = DatabaseHelper.instance;
  final userDataSource = UserLocalDataSourceImpl(dbHelper);
  final sessionDataSource = SessionLocalDataSource();
  final gameDataSource = GameLocalDataSourceImpl(dbHelper);
  final backlogDataSource = GameBacklogLocalDataSourceImpl(dbHelper);

  // Crear AuthProvider
  final authProvider = AuthProvider(
    userDataSource: userDataSource,
    sessionDataSource: sessionDataSource,
  );

  // Inicializar autenticación
  await authProvider.initializeAuth();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        // BacklogProvider se crea dinámicamente cuando hay un usuario autenticado
        ChangeNotifierProxyProvider<AuthProvider, BacklogProvider?>(
          create: (_) => null,
          update: (context, authProvider, previous) {
            if (authProvider.currentUser != null) {
              return BacklogProvider(
                userId: authProvider.currentUser!.id,
                gameDataSource: gameDataSource,
                backlogDataSource: backlogDataSource,
              );
            }
            return null;
          },
        ),
      ],
      child: MyApp(authProvider: authProvider),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;

  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter(authProvider);

    return MaterialApp.router(
      title: 'Game Backlog',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter.router,
    );
  }
}
