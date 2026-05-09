import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/game_list_model.dart';
import '../../models/game_list_item_model.dart';

class GameListSupabaseDataSource {
  final SupabaseClient _client;

  GameListSupabaseDataSource(this._client);

  // ─── Listas ───

  Future<List<GameListModel>> getListsByUserId(String userId) async {
    final result = await _client
        .from('game_lists')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return (result as List).map((json) => GameListModel.fromJson(json)).toList();
  }

  Future<GameListModel?> getListById(String listId) async {
    final result = await _client
        .from('game_lists')
        .select()
        .eq('id', listId)
        .maybeSingle();
    if (result == null) return null;
    return GameListModel.fromJson(result);
  }

  Future<void> insertList(GameListModel list) async {
    await _client.from('game_lists').insert(list.toJson());
  }

  Future<void> updateList(GameListModel list) async {
    await _client.from('game_lists').update(list.toJson()).eq('id', list.id);
  }

  Future<void> deleteList(String listId) async {
    await _client.from('game_lists').delete().eq('id', listId);
  }

  // ─── Items de Lista ───

  Future<List<GameListItemModel>> getItemsByListId(String listId) async {
    final result = await _client
        .from('game_list_items')
        .select()
        .eq('list_id', listId)
        .order('added_at', ascending: false);
    return (result as List).map((json) => GameListItemModel.fromJson(json)).toList();
  }

  Future<void> addGameToList(GameListItemModel item) async {
    await _client.from('game_list_items').insert(item.toJson());
  }

  Future<void> removeGameFromList(String listId, String gameId) async {
    await _client
        .from('game_list_items')
        .delete()
        .eq('list_id', listId)
        .eq('game_id', gameId);
  }

  Future<bool> isGameInList(String listId, String gameId) async {
    final result = await _client
        .from('game_list_items')
        .select('id')
        .eq('list_id', listId)
        .eq('game_id', gameId)
        .maybeSingle();
    return result != null;
  }

  Future<List<GameListModel>> getListsContainingGame(String gameId, String userId) async {
    // Get list IDs that contain the game
    final items = await _client
        .from('game_list_items')
        .select('list_id')
        .eq('game_id', gameId);
    
    if ((items as List).isEmpty) return [];

    final listIds = items.map((i) => i['list_id'] as String).toList();
    
    final result = await _client
        .from('game_lists')
        .select()
        .inFilter('id', listIds)
        .eq('user_id', userId)
        .order('name');
    return (result as List).map((json) => GameListModel.fromJson(json)).toList();
  }

  Future<int> getItemCount(String listId) async {
    final result = await _client
        .from('game_list_items')
        .select('id')
        .eq('list_id', listId);
    return (result as List).length;
  }
}
