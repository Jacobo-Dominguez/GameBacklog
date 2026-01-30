import 'package:uuid/uuid.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/game_search_result.dart';

class GameSearchService {
  /// Convierte un resultado de RAWG a tu modelo Game local
  Game fromRawgResult(GameSearchResult rawgResult, String userId) {
    // Validación de seguridad para userId
    if (userId.isEmpty) {
      throw ArgumentError('userId no puede estar vacío');
    }

    // Extraer y procesar datos con null safety explícita
    final String title = rawgResult.name.trim();
    final String? coverUrl = rawgResult.backgroundImage?.trim();
    final int remoteId = rawgResult.id;
    
    // Procesar releaseDate de forma segura
    DateTime? releaseDate;
    final String? releasedStr = rawgResult.released;
    if (releasedStr != null && releasedStr.isNotEmpty) {
      releaseDate = DateTime.tryParse(releasedStr);
    }
    
    // Procesar platform (primer plataforma si existe)
    String? platform;
    if (rawgResult.platforms.isNotEmpty) {
      platform = rawgResult.platforms.first.trim();
    }
    
    // Procesar genre (primer género si existe)
    String? genre;
    if (rawgResult.genres.isNotEmpty) {
      genre = rawgResult.genres.first.trim();
    }

    return Game(
      id: const Uuid().v4(),
      title: title,
      coverUrl: coverUrl,
      description: null, // No disponible en búsquedas de RAWG
      remoteId: remoteId,
      releaseDate: releaseDate,
      platform: platform,
      genre: genre,
      userId: userId.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}