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
      version: 8,
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

    if (oldVersion < 7) {
      // Migración a versión 7: Múltiples Reseñas
      await db.execute('''
        CREATE TABLE user_reviews (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          game_id TEXT NOT NULL,
          title TEXT,
          content TEXT,
          rating INTEGER,
          is_spoiler INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX idx_user_reviews_game ON user_reviews(game_id)');
      await db.execute('CREATE INDEX idx_user_reviews_user ON user_reviews(user_id)');

      // Migrar reseñas existentes (opcional pero recomendado)
      final existingReviews = await db.query('game_backlog', where: 'notes IS NOT NULL OR review_title IS NOT NULL');
      for (var row in existingReviews) {
        if (row['notes'] != null || row['review_title'] != null) {
          await db.insert('user_reviews', {
            'id': 'migrated_${row['id']}',
            'user_id': row['user_id'],
            'game_id': row['game_id'],
            'title': row['review_title'],
            'content': row['notes'],
            'rating': row['rating'],
            'is_spoiler': row['is_spoiler'],
            'created_at': row['added_date'] ?? DateTime.now().toIso8601String(),
            'updated_at': row['last_updated'] ?? DateTime.now().toIso8601String(),
          });
        }
      }
    }

    if (oldVersion < 8) {
      // Migración a versión 8: Corregir review_likes para apuntar a user_reviews
      await db.execute('DROP TABLE IF EXISTS review_likes');
      await db.execute('''
        CREATE TABLE review_likes (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          review_id TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY (review_id) REFERENCES user_reviews(id) ON DELETE CASCADE,
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

    // Tabla user_reviews - v7
    await db.execute('''
      CREATE TABLE user_reviews (
        id $idType,
        user_id $textType,
        game_id $textType,
        title $textTypeNullable,
        content $textTypeNullable,
        rating $intTypeNullable,
        is_spoiler $intType DEFAULT 0,
        created_at $textType,
        updated_at $textType,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_user_reviews_game ON user_reviews(game_id)');
    await db.execute('CREATE INDEX idx_user_reviews_user ON user_reviews(user_id)');
  }

  // Borrar datos mock (opcional, para limpiar la base de datos actual)
  Future<void> clearMockData() async {
    final db = await instance.database;
    await db.delete('users', where: "id LIKE 'mock_user_%'");
    await db.delete('games', where: "id LIKE 'mock_game_%'");
    await db.delete('user_reviews', where: "id LIKE 'migrated_mock_%'");
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
