import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/backlog_provider.dart';
import 'presentation/providers/community_provider.dart';
import 'data/datasources/database_helper.dart';
import 'data/datasources/game_local_datasource_impl.dart';
import 'data/datasources/game_backlog_local_datasource_impl.dart';
import 'data/datasources/game_session_local_datasource.dart';
import 'data/datasources/game_list_local_datasource.dart';
import 'data/datasources/review_local_datasource.dart';
import 'data/datasources/community_local_datasource.dart';
import 'data/datasources/user_local_datasource_impl.dart';
import 'data/datasources/session_local_datasource.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Aviso: No se pudo cargar el archivo .env: $e");
  }

  final dbHelper = DatabaseHelper.instance;
  await dbHelper.database;

  // Inicializar todos los DataSources
  final gameDataSource = GameLocalDataSourceImpl(dbHelper);
  final backlogDataSource = GameBacklogLocalDataSourceImpl(dbHelper);
  final gameSessionDataSource = GameSessionLocalDataSource(dbHelper);
  final listDataSource = GameListLocalDataSource(dbHelper);
  final reviewDataSource = ReviewLocalDataSource(dbHelper);
  final communityDataSource = CommunityLocalDataSource(dbHelper);
  final userDataSource = UserLocalDataSourceImpl(dbHelper);
  final sessionDataSource = SessionLocalDataSource();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            userDataSource: userDataSource,
            sessionDataSource: sessionDataSource,
          )..initializeAuth(),
        ),
        
        ChangeNotifierProxyProvider<AuthProvider, BacklogProvider>(
          create: (context) => BacklogProvider(
            userId: '', 
            gameDataSource: gameDataSource,
            backlogDataSource: backlogDataSource,
            sessionDataSource: gameSessionDataSource,
            listDataSource: listDataSource,
            reviewDataSource: reviewDataSource,
          ),
          update: (_, auth, previous) {
            final user = auth.currentUser;
            return BacklogProvider(
              userId: user?.id ?? '',
              gameDataSource: gameDataSource,
              backlogDataSource: backlogDataSource,
              sessionDataSource: gameSessionDataSource,
              listDataSource: listDataSource,
              reviewDataSource: reviewDataSource,
            );
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, CommunityProvider>(
          create: (context) => CommunityProvider(
            dataSource: communityDataSource,
            currentUserId: '',
          ),
          update: (_, auth, previous) {
            final user = auth.currentUser;
            return CommunityProvider(
              dataSource: communityDataSource,
              currentUserId: user?.id ?? '',
            );
          },
        ),
        
        ProxyProvider<AuthProvider, AppRouter>(
          update: (_, auth, __) => AppRouter(auth),
        ),
      ],
      child: const GameBacklogApp(),
    ),
  );
}

class GameBacklogApp extends StatelessWidget {
  const GameBacklogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = Provider.of<AppRouter>(context, listen: false);

    return MaterialApp.router(
      title: 'GameBacklog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter.router,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
            scrollbars: false,
          ),
          child: child!,
        );
      },
    );
  }
}
