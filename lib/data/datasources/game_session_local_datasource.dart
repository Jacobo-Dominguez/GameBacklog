import 'database_helper.dart';
import '../models/game_session_model.dart';
import '../../domain/entities/game_session.dart';

class GameSessionLocalDataSource {
  final DatabaseHelper dbHelper;

  GameSessionLocalDataSource(this.dbHelper);

  Future<void> insertSession(GameSessionModel session) async {
    final db = await dbHelper.database;
    await db.insert('game_sessions', session.toJson());
  }

  Future<List<GameSession>> getSessionsByUserId(String userId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'game_sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'session_date DESC',
    );

    return List.generate(maps.length, (i) {
      return GameSessionModel.fromJson(maps[i]);
    });
  }

  Future<List<GameSession>> getSessionsByGameId(String gameId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'game_sessions',
      where: 'game_id = ?',
      whereArgs: [gameId],
      orderBy: 'session_date DESC',
    );

    return List.generate(maps.length, (i) {
      return GameSessionModel.fromJson(maps[i]);
    });
  }

  Future<void> updateSession(GameSessionModel session) async {
    final db = await dbHelper.database;
    await db.update(
      'game_sessions',
      session.toJson(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> deleteSession(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      'game_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
