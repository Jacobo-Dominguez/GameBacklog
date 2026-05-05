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
    
    // Procesar platforms (todas unidas por coma)
    String? platform;
    if (rawgResult.platforms.isNotEmpty) {
      platform = rawgResult.platforms.join(', ');
    }
    
    // Procesar genres (todos unidos por coma)
    String? genre;
    if (rawgResult.genres.isNotEmpty) {
      genre = rawgResult.genres.join(', ');
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

  /// Convierte un resultado de IGDB a tu modelo Game local
  Game fromIgdbResult(Map<String, dynamic> igdbResult, String userId) {
    // Validaciones básicas
    if (userId.isEmpty) throw ArgumentError('userId no puede estar vacío');

    // Procesar listas (pueden venir nulas si no se pidieron o no existen)
    final genres = (igdbResult['genres'] as List?)?.map((g) => g['name'] as String).toList() ?? [];
    final platforms = (igdbResult['platforms'] as List?)?.map((p) => p['name'] as String).toList() ?? [];
    
    // Descripción: Preferencia por storyline, luego summary, o combinados
    final summary = igdbResult['summary'] as String?;
    final storyline = igdbResult['storyline'] as String?;
    final description = summary != null 
        ? (storyline != null ? '$summary\n\n$storyline' : summary)
        : storyline;

    // Cover URL: IGDB devuelve "//images.igdb.com/..."
    String? coverUrl;
    if (igdbResult['cover'] != null && igdbResult['cover']['url'] != null) {
        final rawUrl = igdbResult['cover']['url'] as String;
        // Reemplazar t_thumb por t_cover_big para mejor resolución
        final bigUrl = rawUrl.replaceAll('t_thumb', 't_cover_big');
        coverUrl = 'https:$bigUrl'; 
    }

    // Fecha de lanzamiento (Unix timestamp)
    DateTime? releaseDate;
    if (igdbResult['first_release_date'] != null) {
        releaseDate = DateTime.fromMillisecondsSinceEpoch((igdbResult['first_release_date'] as int) * 1000);
    }

    return Game(
      id: const Uuid().v4(),
      title: igdbResult['name'] as String,
      coverUrl: coverUrl,
      description: description,
      remoteId: igdbResult['id'] as int?,
      releaseDate: releaseDate,
      platform: platforms.isNotEmpty ? platforms.join(', ') : null,
      genre: genres.isNotEmpty ? genres.join(', ') : null,
      userId: userId.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}