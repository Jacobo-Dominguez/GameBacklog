import '../../domain/entities/game.dart';
import '../../domain/entities/game_search_result.dart';

class GameDetailMapper {
  /// Enriquece un objeto Game existente con detalles de la API
  static Game enrichGameWithDetails(Game originalGame, Map<String, dynamic> apiDetails) {
    return Game(
      id: originalGame.id,
      title: originalGame.title,
      platform: originalGame.platform, // Mantener o actualizar si se desea
      genre: originalGame.genre,
      releaseDate: originalGame.releaseDate ?? DateTime.tryParse(apiDetails['released'] ?? ''),
      coverUrl: originalGame.coverUrl ?? apiDetails['background_image'],
      description: apiDetails['description_raw'] ?? apiDetails['description'], // Preferir raw (texto plano)
      remoteId: originalGame.remoteId,
      createdAt: originalGame.createdAt,
      updatedAt: DateTime.now(),
      userId: originalGame.userId,
    );
  }
}
