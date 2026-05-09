import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/game_session_model.dart';
import '../../../domain/entities/game_session.dart';

class GameSessionSupabaseDataSource {
  final SupabaseClient _client;

  GameSessionSupabaseDataSource(this._client);

  Future<void> insertSession(GameSessionModel session) async {
    await _client.from('game_sessions').insert(session.toJson());
  }

  Future<List<GameSession>> getSessionsByUserId(String userId) async {
    final result = await _client
        .from('game_sessions')
        .select()
        .eq('user_id', userId)
        .order('session_date', ascending: false);
    return (result as List).map((json) => GameSessionModel.fromJson(json)).toList();
  }

  Future<List<GameSession>> getSessionsByGameId(String gameId) async {
    final result = await _client
        .from('game_sessions')
        .select()
        .eq('game_id', gameId)
        .order('session_date', ascending: false);
    return (result as List).map((json) => GameSessionModel.fromJson(json)).toList();
  }

  Future<void> updateSession(GameSessionModel session) async {
    await _client.from('game_sessions').update(session.toJson()).eq('id', session.id);
  }

  Future<void> deleteSession(String id) async {
    await _client.from('game_sessions').delete().eq('id', id);
  }
}
