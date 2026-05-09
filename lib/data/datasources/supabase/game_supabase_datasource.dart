import 'package:supabase_flutter/supabase_flutter.dart';
import '../game_local_datasource.dart';
import '../../models/game_model.dart';

class GameSupabaseDataSource implements GameLocalDataSource {
  final SupabaseClient _client;

  GameSupabaseDataSource(this._client);

  @override
  Future<List<GameModel>> getAllGames() async {
    final result = await _client.from('games').select().order('title');
    return (result as List).map((json) => GameModel.fromJson(json)).toList();
  }

  @override
  Future<GameModel?> getGameById(String id) async {
    final result = await _client
        .from('games')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (result != null) {
      return GameModel.fromJson(result);
    }
    return null;
  }

  @override
  Future<void> insertGame(GameModel game) async {
    await _client.from('games').upsert(game.toJson());
  }

  @override
  Future<void> updateGame(GameModel game) async {
    await _client.from('games').update(game.toJson()).eq('id', game.id);
  }

  @override
  Future<void> deleteGame(String id) async {
    await _client.from('games').delete().eq('id', id);
  }

  @override
  Future<List<GameModel>> searchGames(String query) async {
    final result = await _client
        .from('games')
        .select()
        .ilike('title', '%$query%')
        .order('title');
    return (result as List).map((json) => GameModel.fromJson(json)).toList();
  }
}
