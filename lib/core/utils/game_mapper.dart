import 'package:uuid/uuid.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/game_search_result.dart';

class GameMapper {
  /// Convierte un resultado de RAWG a tu modelo Game local
  static Game fromRawgResult(GameSearchResult rawgResult, String userId) {
    return Game(
      id: const Uuid().v4(),
      title: rawgResult.name,
      coverUrl: rawgResult.backgroundImage,
      description: null, // RAWG search results don't usually include description, need separate details call
      remoteId: rawgResult.id,
      releaseDate: rawgResult.released != null 
          ? DateTime.tryParse(rawgResult.released!) 
          : null,
      platform: rawgResult.platforms.isNotEmpty 
          ? rawgResult.platforms.first 
          : null,
      genre: rawgResult.genres.isNotEmpty 
          ? rawgResult.genres.first 
          : null,
      userId: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
