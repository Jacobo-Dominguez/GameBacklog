import 'database_helper.dart';
import '../models/game_list_model.dart';
import '../models/game_list_item_model.dart';

class GameListLocalDataSource {
  final DatabaseHelper dbHelper;

  GameListLocalDataSource(this.dbHelper);

  // ─── Listas ───

  Future<List<GameListModel>> getListsByUserId(String userId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'game_lists',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
    return result.map((json) => GameListModel.fromJson(json)).toList();
  }

  Future<GameListModel?> getListById(String listId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'game_lists',
      where: 'id = ?',
      whereArgs: [listId],
    );
    if (result.isEmpty) return null;
    return GameListModel.fromJson(result.first);
  }

  Future<void> insertList(GameListModel list) async {
    final db = await dbHelper.database;
    await db.insert('game_lists', list.toJson());
  }

  Future<void> updateList(GameListModel list) async {
    final db = await dbHelper.database;
    await db.update(
      'game_lists',
      list.toJson(),
      where: 'id = ?',
      whereArgs: [list.id],
    );
  }

  Future<void> deleteList(String listId) async {
    final db = await dbHelper.database;
    // Los items se borran en cascada por la FK
    await db.delete('game_lists', where: 'id = ?', whereArgs: [listId]);
  }

  // ─── Items de Lista ───

  Future<List<GameListItemModel>> getItemsByListId(String listId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'game_list_items',
      where: 'list_id = ?',
      whereArgs: [listId],
      orderBy: 'added_at DESC',
    );
    return result.map((json) => GameListItemModel.fromJson(json)).toList();
  }

  Future<void> addGameToList(GameListItemModel item) async {
    final db = await dbHelper.database;
    await db.insert('game_list_items', item.toJson());
  }

  Future<void> removeGameFromList(String listId, String gameId) async {
    final db = await dbHelper.database;
    await db.delete(
      'game_list_items',
      where: 'list_id = ? AND game_id = ?',
      whereArgs: [listId, gameId],
    );
  }

  Future<bool> isGameInList(String listId, String gameId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'game_list_items',
      where: 'list_id = ? AND game_id = ?',
      whereArgs: [listId, gameId],
    );
    return result.isNotEmpty;
  }

  Future<List<GameListModel>> getListsContainingGame(String gameId, String userId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
      SELECT gl.* FROM game_lists gl
      INNER JOIN game_list_items gli ON gl.id = gli.list_id
      WHERE gli.game_id = ? AND gl.user_id = ?
      ORDER BY gl.name ASC
    ''', [gameId, userId]);
    return result.map((json) => GameListModel.fromJson(json)).toList();
  }

  Future<int> getItemCount(String listId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM game_list_items WHERE list_id = ?',
      [listId],
    );
    return result.first['count'] as int;
  }
}
