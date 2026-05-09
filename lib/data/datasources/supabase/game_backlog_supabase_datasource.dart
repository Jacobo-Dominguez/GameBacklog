import 'package:supabase_flutter/supabase_flutter.dart';
import '../game_backlog_local_datasource.dart';
import '../../models/game_backlog_model.dart';

class GameBacklogSupabaseDataSource implements GameBacklogLocalDataSource {
  final SupabaseClient _client;

  GameBacklogSupabaseDataSource(this._client);

  @override
  Future<List<GameBacklogModel>> getBacklogByUserId(String userId) async {
    final result = await _client
        .from('game_backlog')
        .select()
        .eq('user_id', userId)
        .order('added_date', ascending: false);
    return (result as List).map((json) => GameBacklogModel.fromJson(json)).toList();
  }

  @override
  Future<List<GameBacklogModel>> getBacklogByStatus(String userId, String status) async {
    final result = await _client
        .from('game_backlog')
        .select()
        .eq('user_id', userId)
        .eq('status', status)
        .order('added_date', ascending: false);
    return (result as List).map((json) => GameBacklogModel.fromJson(json)).toList();
  }

  @override
  Future<GameBacklogModel?> getBacklogEntry(String userId, String gameId) async {
    final result = await _client
        .from('game_backlog')
        .select()
        .eq('user_id', userId)
        .eq('game_id', gameId)
        .maybeSingle();
    if (result != null) {
      return GameBacklogModel.fromJson(result);
    }
    return null;
  }

  @override
  Future<void> insertBacklogEntry(GameBacklogModel entry) async {
    await _client.from('game_backlog').upsert(entry.toJson());
  }

  @override
  Future<void> updateBacklogEntry(GameBacklogModel entry) async {
    await _client.from('game_backlog').update(entry.toJson()).eq('id', entry.id);
  }

  @override
  Future<void> deleteBacklogEntry(String id) async {
    await _client.from('game_backlog').delete().eq('id', id);
  }

  @override
  Future<Map<String, int>> getStatsByUserId(String userId) async {
    final result = await _client
        .from('game_backlog')
        .select('status')
        .eq('user_id', userId);
    
    final stats = <String, int>{};
    for (var row in (result as List)) {
      final status = row['status'] as String;
      stats[status] = (stats[status] ?? 0) + 1;
    }
    return stats;
  }
}
