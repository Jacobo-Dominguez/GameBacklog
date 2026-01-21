import '../models/game_model.dart';

abstract class GameLocalDataSource {
  Future<List<GameModel>> getAllGames();
  Future<GameModel?> getGameById(String id);
  Future<void> insertGame(GameModel game);
  Future<void> updateGame(GameModel game);
  Future<void> deleteGame(String id);
  Future<List<GameModel>> searchGames(String query);
}
