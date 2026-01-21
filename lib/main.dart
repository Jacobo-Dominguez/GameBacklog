import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/database_helper.dart';
import 'data/datasources/user_local_datasource_impl.dart';
import 'data/datasources/session_local_datasource.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar dependencias
  final dbHelper = DatabaseHelper.instance;
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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Backlog',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Mostrar loading mientras se inicializa
          if (authProvider.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Si está autenticado, mostrar pantalla de bienvenida temporal
          if (authProvider.isAuthenticated) {
            return _HomeScreen(user: authProvider.currentUser!);
          }

          // Si no está autenticado, mostrar login
          return const LoginScreen();
        },
      ),
    );
  }
}

// Pantalla temporal de bienvenida (será reemplazada en la siguiente fase)
class _HomeScreen extends StatelessWidget {
  final dynamic user;

  const _HomeScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Backlog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                '¡Bienvenido, ${user.username}!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Email: ${user.email}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        '✅ Autenticación completada',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text('• Login funcional'),
                      Text('• Registro funcional'),
                      Text('• Sesión persistente'),
                      Text('• Contraseñas encriptadas'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Próxima fase: Navegación y UI completa',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
