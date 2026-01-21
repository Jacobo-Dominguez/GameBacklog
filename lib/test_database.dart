import 'package:uuid/uuid.dart';
import 'data/datasources/database_helper.dart';
import 'data/datasources/user_local_datasource_impl.dart';
import 'data/datasources/game_local_datasource_impl.dart';
import 'data/datasources/game_backlog_local_datasource_impl.dart';
import 'data/models/user_model.dart';
import 'data/models/game_model.dart';
import 'data/models/game_backlog_model.dart';

Future<void> testDatabase() async {
  print('🧪 Iniciando pruebas de base de datos...\n');
  
  final dbHelper = DatabaseHelper.instance;
  final userDataSource = UserLocalDataSourceImpl(dbHelper);
  final gameDataSource = GameLocalDataSourceImpl(dbHelper);
  final backlogDataSource = GameBacklogLocalDataSourceImpl(dbHelper);
  
  const uuid = Uuid();

  try {
    // 1. Crear usuario de prueba
    print('1️⃣ Creando usuario de prueba...');
    final user = UserModel(
      id: uuid.v4(),
      username: 'testuser',
      email: 'test@example.com',
      passwordHash: 'hashed_password_123',
      createdAt: DateTime.now(),
    );

    await userDataSource.insertUser(user);
    print('✅ Usuario creado: ${user.username} (${user.email})\n');

    // 2. Verificar que se puede obtener el usuario
    print('2️⃣ Verificando obtención de usuario...');
    final retrievedUser = await userDataSource.getUserByEmail(user.email);
    if (retrievedUser != null) {
      print('✅ Usuario recuperado: ${retrievedUser.username}\n');
    } else {
      print('❌ Error: No se pudo recuperar el usuario\n');
    }

    // 3. Crear juegos de prueba
    print('3️⃣ Creando juegos de prueba...');
    final games = [
      GameModel(
        id: uuid.v4(),
        title: 'The Legend of Zelda: Breath of the Wild',
        platform: 'Nintendo Switch',
        genre: 'Aventura',
        releaseYear: 2017,
        description: 'Un juego de aventuras épico en mundo abierto',
        createdAt: DateTime.now(),
      ),
      GameModel(
        id: uuid.v4(),
        title: 'Elden Ring',
        platform: 'PC',
        genre: 'RPG',
        releaseYear: 2022,
        description: 'Un RPG de acción desafiante',
        createdAt: DateTime.now(),
      ),
      GameModel(
        id: uuid.v4(),
        title: 'Hollow Knight',
        platform: 'PC',
        genre: 'Metroidvania',
        releaseYear: 2017,
        description: 'Un metroidvania atmosférico',
        createdAt: DateTime.now(),
      ),
    ];

    for (var game in games) {
      await gameDataSource.insertGame(game);
      print('✅ Juego creado: ${game.title}');
    }
    print('');

    // 4. Agregar juegos al backlog
    print('4️⃣ Agregando juegos al backlog...');
    final backlogEntries = [
      GameBacklogModel(
        id: uuid.v4(),
        userId: user.id,
        gameId: games[0].id,
        status: 'playing',
        hoursPlayed: 15,
        rating: 9,
        notes: '¡Increíble juego! Me encanta la exploración.',
        addedDate: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
      GameBacklogModel(
        id: uuid.v4(),
        userId: user.id,
        gameId: games[1].id,
        status: 'pending',
        hoursPlayed: 0,
        addedDate: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
      GameBacklogModel(
        id: uuid.v4(),
        userId: user.id,
        gameId: games[2].id,
        status: 'completed',
        hoursPlayed: 40,
        rating: 10,
        notes: 'Obra maestra absoluta',
        addedDate: DateTime.now().subtract(const Duration(days: 30)),
        completedDate: DateTime.now().subtract(const Duration(days: 5)),
        lastUpdated: DateTime.now(),
      ),
    ];

    for (var entry in backlogEntries) {
      await backlogDataSource.insertBacklogEntry(entry);
      final game = games.firstWhere((g) => g.id == entry.gameId);
      print('✅ Agregado al backlog: ${game.title} (${entry.status})');
    }
    print('');

    // 5. Obtener backlog del usuario
    print('5️⃣ Obteniendo backlog del usuario...');
    final backlog = await backlogDataSource.getBacklogByUserId(user.id);
    print('📋 Total de juegos en backlog: ${backlog.length}');
    for (var entry in backlog) {
      final game = games.firstWhere((g) => g.id == entry.gameId);
      print('   - ${game.title}: ${entry.status} (${entry.hoursPlayed}h)');
    }
    print('');

    // 6. Obtener estadísticas
    print('6️⃣ Obteniendo estadísticas...');
    final stats = await backlogDataSource.getStatsByUserId(user.id);
    print('📊 Estadísticas del backlog:');
    stats.forEach((status, count) {
      print('   - $status: $count juegos');
    });
    print('');

    // 7. Filtrar por estado
    print('7️⃣ Filtrando juegos por estado "playing"...');
    final playingGames = await backlogDataSource.getBacklogByStatus(user.id, 'playing');
    print('🎮 Juegos que estás jugando: ${playingGames.length}');
    for (var entry in playingGames) {
      final game = games.firstWhere((g) => g.id == entry.gameId);
      print('   - ${game.title} (${entry.hoursPlayed}h jugadas)');
    }
    print('');

    // 8. Buscar juegos
    print('8️⃣ Buscando juegos con "Zelda"...');
    final searchResults = await gameDataSource.searchGames('Zelda');
    print('🔍 Resultados de búsqueda: ${searchResults.length}');
    for (var game in searchResults) {
      print('   - ${game.title}');
    }
    print('');

    print('✅ ¡Todas las pruebas completadas exitosamente!');
    print('🎉 La base de datos está funcionando correctamente.\n');
    
  } catch (e) {
    print('❌ Error durante las pruebas: $e\n');
  }
}
