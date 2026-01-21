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
      version: 1,
      onCreate: _createDB,
    );
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

    // Tabla games
    await db.execute('''
      CREATE TABLE games (
        id $idType,
        title $textType,
        cover_url $textTypeNullable,
        description $textTypeNullable,
        platform $textTypeNullable,
        genre $textTypeNullable,
        release_year $intTypeNullable,
        created_at $textType
      )
    ''');

    // Tabla game_backlog
    await db.execute('''
      CREATE TABLE game_backlog (
        id $idType,
        user_id $textType,
        game_id $textType,
        status $textType CHECK(status IN ('playing', 'completed', 'pending', 'dropped', 'on_hold')),
        hours_played $intType DEFAULT 0,
        rating $intTypeNullable CHECK(rating >= 0 AND rating <= 10),
        notes $textTypeNullable,
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
