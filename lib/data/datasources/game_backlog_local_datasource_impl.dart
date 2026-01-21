import 'package:sqflite/sqflite.dart';
import '../models/game_backlog_model.dart';
import 'database_helper.dart';
import 'game_backlog_local_datasource.dart';

class GameBacklogLocalDataSourceImpl implements GameBacklogLocalDataSource {
  final DatabaseHelper dbHelper;

  GameBacklogLocalDataSourceImpl(this.dbHelper);

  @override
  Future<List<GameBacklogModel>> getBacklogByUserId(String userId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'game_backlog',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'added_date DESC',
    );
    return result.map((json) => GameBacklogModel.fromJson(json)).toList();
  }

  @override
  Future<List<GameBacklogModel>> getBacklogByStatus(
    String userId,
    String status,
  ) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'game_backlog',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, status],
      orderBy: 'added_date DESC',
    );
    return result.map((json) => GameBacklogModel.fromJson(json)).toList();
  }

  @override
  Future<GameBacklogModel?> getBacklogEntry(
    String userId,
    String gameId,
  ) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'game_backlog',
      where: 'user_id = ? AND game_id = ?',
      whereArgs: [userId, gameId],
    );
    
    if (result.isNotEmpty) {
      return GameBacklogModel.fromJson(result.first);
    }
    return null;
  }

  @override
  Future<void> insertBacklogEntry(GameBacklogModel entry) async {
    final db = await dbHelper.database;
    await db.insert(
      'game_backlog',
      entry.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateBacklogEntry(GameBacklogModel entry) async {
    final db = await dbHelper.database;
    await db.update(
      'game_backlog',
      entry.toJson(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  @override
  Future<void> deleteBacklogEntry(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      'game_backlog',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<Map<String, int>> getStatsByUserId(String userId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM game_backlog
      WHERE user_id = ?
      GROUP BY status
    ''', [userId]);

    final stats = <String, int>{};
    for (var row in result) {
      stats[row['status'] as String] = row['count'] as int;
    }
    return stats;
  }
}
