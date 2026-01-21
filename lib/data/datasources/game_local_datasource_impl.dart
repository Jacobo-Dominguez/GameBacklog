import 'package:sqflite/sqflite.dart';
import '../models/game_model.dart';
import 'database_helper.dart';
import 'game_local_datasource.dart';

class GameLocalDataSourceImpl implements GameLocalDataSource {
  final DatabaseHelper dbHelper;

  GameLocalDataSourceImpl(this.dbHelper);

  @override
  Future<List<GameModel>> getAllGames() async {
    final db = await dbHelper.database;
    final result = await db.query('games', orderBy: 'title ASC');
    return result.map((json) => GameModel.fromJson(json)).toList();
  }

  @override
  Future<GameModel?> getGameById(String id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'games',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isNotEmpty) {
      return GameModel.fromJson(result.first);
    }
    return null;
  }

  @override
  Future<void> insertGame(GameModel game) async {
    final db = await dbHelper.database;
    await db.insert(
      'games',
      game.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateGame(GameModel game) async {
    final db = await dbHelper.database;
    await db.update(
      'games',
      game.toJson(),
      where: 'id = ?',
      whereArgs: [game.id],
    );
  }

  @override
  Future<void> deleteGame(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      'games',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<GameModel>> searchGames(String query) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'games',
      where: 'title LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'title ASC',
    );
    return result.map((json) => GameModel.fromJson(json)).toList();
  }
}
