import '../models/game_backlog_model.dart';

abstract class GameBacklogLocalDataSource {
  Future<List<GameBacklogModel>> getBacklogByUserId(String userId);
  Future<List<GameBacklogModel>> getBacklogByStatus(String userId, String status);
  Future<GameBacklogModel?> getBacklogEntry(String userId, String gameId);
  Future<void> insertBacklogEntry(GameBacklogModel entry);
  Future<void> updateBacklogEntry(GameBacklogModel entry);
  Future<void> deleteBacklogEntry(String id);
  Future<Map<String, int>> getStatsByUserId(String userId);
}
