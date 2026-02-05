import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Inicializar sqflite_common_ffi para Windows
    if (Platform.isWindows || Platform.isLinux) {
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
      version: 3,
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
        added_date $textType,
        completed_date $textTypeNullable,
        last_updated $textType,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
        UNIQUE(user_id, game_id)
      )
    ''');

    // Crear índices para mejorar rendimiento
    await db.execute('CREATE INDEX idx_backlog_user ON game_backlog(user_id)');
    await db.execute('CREATE INDEX idx_backlog_status ON game_backlog(status)');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
