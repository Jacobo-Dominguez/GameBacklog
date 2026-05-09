import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/backlog_provider.dart';
import 'presentation/providers/community_provider.dart';

// Importaciones de Supabase DataSources
import 'data/datasources/supabase/game_supabase_datasource.dart';
import 'data/datasources/supabase/game_backlog_supabase_datasource.dart';
import 'data/datasources/supabase/game_session_supabase_datasource.dart';
import 'data/datasources/supabase/game_list_supabase_datasource.dart';
import 'data/datasources/supabase/review_supabase_datasource.dart';
import 'data/datasources/supabase/community_supabase_datasource.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Aviso: No se pudo cargar el archivo .env: $e");
  }

  // Inicializar Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl != null && supabaseAnonKey != null) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } else {
    debugPrint("ERROR CRÍTICO: Faltan credenciales de Supabase en .env");
  }

  final supabaseClient = Supabase.instance.client;

  // Inicializar todos los DataSources de Supabase
  final gameDataSource = GameSupabaseDataSource(supabaseClient);
  final backlogDataSource = GameBacklogSupabaseDataSource(supabaseClient);
  final gameSessionDataSource = GameSessionSupabaseDataSource(supabaseClient);
  final listDataSource = GameListSupabaseDataSource(supabaseClient);
  final reviewDataSource = ReviewSupabaseDataSource(supabaseClient);
  final communityDataSource = CommunitySupabaseDataSource(supabaseClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initializeAuth(),
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
