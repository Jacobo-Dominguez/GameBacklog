import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Inicialización para Web
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      _database = await _initDB('game_backlog.db');
      return _database!;
    }

    // Inicialización para Desktop (Windows/Linux/MacOS)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    _database = await _initDB('game_backlog.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('ALTER TABLE games ADD COLUMN coverUrl TEXT');
    await db.execute('ALTER TABLE games ADD COLUMN description TEXT');
    await db.execute('ALTER TABLE games ADD COLUMN remoteId INTEGER');
    await db.execute("ALTER TABLE games ADD COLUMN userId TEXT NOT NULL DEFAULT 'migrated_user'");
    await db.execute('ALTER TABLE games ADD COLUMN updatedAt TEXT');
    await db.execute("UPDATE games SET updatedAt = IFNULL(releaseDate, datetime('now')) WHERE updatedAt IS NULL OR updatedAt = ''");
  }
  
    if (oldVersion < 3) {
      // Migración a versión 3: Reseñas y Favoritos
      await db.execute('ALTER TABLE game_backlog ADD COLUMN is_favorite INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE game_backlog ADD COLUMN review_title TEXT');
      await db.execute('ALTER TABLE game_backlog ADD COLUMN is_spoiler INTEGER DEFAULT 0');
    }

    if (oldVersion < 4) {
      // Migración a versión 4: Diario y Sesiones
      await db.execute('ALTER TABLE game_backlog ADD COLUMN start_date TEXT');
      await db.execute('ALTER TABLE game_backlog ADD COLUMN end_date TEXT');
      
      await db.execute('''
        CREATE TABLE game_sessions (
          id TEXT PRIMARY KEY,
          game_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          session_date TEXT NOT NULL,
          duration_minutes INTEGER NOT NULL,
          description TEXT,
          FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 5) {
      // Migración a versión 5: Listas y Colecciones
      await db.execute('''
        CREATE TABLE game_lists (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE game_list_items (
          id TEXT PRIMARY KEY,
          list_id TEXT NOT NULL,
          game_id TEXT NOT NULL,
          added_at TEXT NOT NULL,
          FOREIGN KEY (list_id) REFERENCES game_lists(id) ON DELETE CASCADE,
          FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
          UNIQUE(list_id, game_id)
        )
      ''');

      await db.execute('CREATE INDEX idx_lists_user ON game_lists(user_id)');
      await db.execute('CREATE INDEX idx_list_items_list ON game_list_items(list_id)');
    }

    if (oldVersion < 6) {
      // Migración a versión 6: Social y Likes
      await db.execute('''
        CREATE TABLE review_likes (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          review_id TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY (review_id) REFERENCES game_backlog(id) ON DELETE CASCADE,
          UNIQUE(user_id, review_id)
        )
      ''');
      await db.execute('CREATE INDEX idx_review_likes_review ON review_likes(review_id)');
    }
}

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textTypeNullable = 'TEXT';
    const intTypeNullable = 'INTEGER';

    // Tabla users
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        username $textType UNIQUE,
        email $textType UNIQUE,
        password_hash $textType,
        avatar_url $textTypeNullable,
        created_at $textType
      )
    ''');

    // Tabla games - Actualizada para v2
    await db.execute('''
      CREATE TABLE games (
        id $idType,
        title $textType,
        platform $textTypeNullable,
        genre $textTypeNullable,
        releaseDate $textTypeNullable,
        coverUrl $textTypeNullable,
        description $textTypeNullable,
        remoteId $intTypeNullable,
        createdAt $textType,
        updatedAt $textType,
        userId $textType
      )
    ''');

    // Tabla game_backlog - v3
    await db.execute('''
      CREATE TABLE game_backlog (
        id $idType,
        user_id $textType,
        game_id $textType,
        status $textType CHECK(status IN ('playing', 'completed', 'pending', 'dropped', 'on_hold')),
        hours_played $intType DEFAULT 0,
        rating $intTypeNullable CHECK(rating >= 0 AND rating <= 10),
        notes $textTypeNullable,
        is_favorite $intType DEFAULT 0,
        review_title $textTypeNullable,
        is_spoiler $intType DEFAULT 0,
        start_date $textTypeNullable,
        end_date $textTypeNullable,
        added_date $textType,
        completed_date $textTypeNullable,
        last_updated $textType,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
        UNIQUE(user_id, game_id)
      )
    ''');

    // Tabla game_sessions - v4
    await db.execute('''
      CREATE TABLE game_sessions (
        id $idType,
        game_id $textType,
        user_id $textType,
        session_date $textType,
        duration_minutes $intType,
        description $textTypeNullable,
        FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Tabla game_lists - v5
    await db.execute('''
      CREATE TABLE game_lists (
        id $idType,
        user_id $textType,
        name $textType,
        description $textTypeNullable,
        created_at $textType,
        updated_at $textType,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Tabla game_list_items - v5
    await db.execute('''
      CREATE TABLE game_list_items (
        id $idType,
        list_id $textType,
        game_id $textType,
        added_at $textType,
        FOREIGN KEY (list_id) REFERENCES game_lists(id) ON DELETE CASCADE,
        FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
        UNIQUE(list_id, game_id)
      )
    ''');

    // Crear índices para mejorar rendimiento
    await db.execute('CREATE INDEX idx_backlog_user ON game_backlog(user_id)');
    await db.execute('CREATE INDEX idx_backlog_status ON game_backlog(status)');
    await db.execute('CREATE INDEX idx_lists_user ON game_lists(user_id)');
    await db.execute('CREATE INDEX idx_list_items_list ON game_list_items(list_id)');

    // Tabla review_likes - v6
    await db.execute('''
      CREATE TABLE review_likes (
        id $idType,
        user_id $textType,
        review_id $textType,
        created_at $textType,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (review_id) REFERENCES game_backlog(id) ON DELETE CASCADE,
        UNIQUE(user_id, review_id)
      )
    ''');
    await db.execute('CREATE INDEX idx_review_likes_review ON review_likes(review_id)');
  }

  // --- MOCK DATA SEED ---
  Future<void> seedCommunityData() async {
    final db = await instance.database;
    
    // Verificar si ya hay datos
    final count = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM users WHERE id LIKE 'mock_user_%'"));
    if (count != null && count > 0) return; // Ya se sembró
    
    final mockUsers = [
      {
        'id': 'mock_user_1',
        'username': 'GamerGirl99',
        'email': 'gamergirl99@example.com',
        'password_hash': 'mock',
        'avatar_url': 'https://api.dicebear.com/7.x/avataaars/png?seed=GamerGirl99',
        'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      },
      {
        'id': 'mock_user_2',
        'username': 'RPG_Master',
        'email': 'rpgmaster@example.com',
        'password_hash': 'mock',
        'avatar_url': 'https://api.dicebear.com/7.x/avataaars/png?seed=RPG_Master',
        'created_at': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
      },
      {
        'id': 'mock_user_3',
        'username': 'Speedrunner',
        'email': 'speed@example.com',
        'password_hash': 'mock',
        'avatar_url': 'https://api.dicebear.com/7.x/avataaars/png?seed=Speedrunner',
        'created_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      }
    ];

    for (var u in mockUsers) {
      await db.insert('users', u, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    final mockGames = [
      {
        'id': 'mock_game_1',
        'title': 'The Witcher 3: Wild Hunt',
        'platform': 'PC',
        'genre': 'RPG',
        'coverUrl': 'https://images.igdb.com/igdb/image/upload/t_cover_big/co1wyy.png',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'userId': 'system'
      },
      {
        'id': 'mock_game_2',
        'title': 'Elden Ring',
        'platform': 'PS5',
        'genre': 'Action RPG',
        'coverUrl': 'https://images.igdb.com/igdb/image/upload/t_cover_big/co4jni.png',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'userId': 'system'
      },
      {
        'id': 'mock_game_3',
        'title': 'Cyberpunk 2077',
        'platform': 'Xbox Series X',
        'genre': 'Action RPG',
        'coverUrl': 'https://images.igdb.com/igdb/image/upload/t_cover_big/co2mvt.png',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'userId': 'system'
      }
    ];

    for (var g in mockGames) {
      await db.insert('games', g, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    final mockReviews = [
      {
        'id': 'mock_review_1',
        'user_id': 'mock_user_1',
        'game_id': 'mock_game_1',
        'status': 'completed',
        'hours_played': 120,
        'rating': 10,
        'review_title': 'Una obra maestra absoluta',
        'notes': 'Increíble narrativa y misiones secundarias que parecen principales. El DLC Blood and Wine es espectacular.',
        'is_spoiler': 0,
        'added_date': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        'last_updated': DateTime.now().subtract(const Duration(days: 10)).toIso8601String()
      },
      {
        'id': 'mock_review_2',
        'user_id': 'mock_user_2',
        'game_id': 'mock_game_2',
        'status': 'playing',
        'hours_played': 45,
        'rating': 9,
        'review_title': 'Difícil pero gratificante',
        'notes': 'El jefe final de la segunda zona es donde realmente empieza el juego. Cuidado cuando llegues a la capital porque el dragón aparece de la nada y destruye todo el puente principal.',
        'is_spoiler': 1,
        'added_date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'last_updated': DateTime.now().subtract(const Duration(days: 5)).toIso8601String()
      },
      {
        'id': 'mock_review_3',
        'user_id': 'mock_user_3',
        'game_id': 'mock_game_3',
        'status': 'completed',
        'hours_played': 60,
        'rating': 8,
        'review_title': 'Un diamante en bruto',
        'notes': 'Tras las actualizaciones, es un juego fantástico. Night City es una de las ciudades más inmersivas que he visitado en un videojuego.',
        'is_spoiler': 0,
        'added_date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'last_updated': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()
      }
    ];

    for (var r in mockReviews) {
      await db.insert('game_backlog', r, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
