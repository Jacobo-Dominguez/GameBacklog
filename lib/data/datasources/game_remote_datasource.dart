import 'dart:async'; // ✅ IMPORTANTE: Agregado para Future
import '../../domain/entities/game_search_result.dart';
import '../services/igdb_service.dart';

class GameRemoteDataSource {
  final IGDBService _igdbService;

  GameRemoteDataSource({IGDBService? igdbService}) 
      : _igdbService = igdbService ?? IGDBService();

  Future<List<Map<String, dynamic>>> searchGamesRaw(String query) async {
    try {
      return await _igdbService.searchGames(query);
    } catch (e) {
      print('Error IGDB raw: $e');
      return [];
    }
  }

  Future<List<GameSearchResult>> searchGames(String query) async {
    try {
      final rawResults = await _igdbService.searchGames(query);
      
      return rawResults.map((json) {
        String? coverUrl;
        if (json['cover'] != null && json['cover']['url'] != null) {
          String rawUrl = json['cover']['url'];
          rawUrl = rawUrl.replaceAll('t_thumb', 't_cover_big');
          coverUrl = 'https:$rawUrl';
        }

        return GameSearchResult(
          id: json['id'] as int,
          name: json['name'] as String,
          backgroundImage: coverUrl,
          released: json['first_release_date'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(json['first_release_date'] * 1000).toString()
              : null,
          platforms: (json['platforms'] as List?)?.map((p) => p['name'] as String).toList() ?? [],
          genres: (json['genres'] as List?)?.map((g) => g['name'] as String).toList() ?? [],
          description: json['summary'] ?? json['storyline'], // ✅ Usar ambos campos
        );
      }).toList();
    } catch (e) {
      print('Error searchGames: $e');
      throw Exception('Error al buscar juegos: $e'); // Rethrow para que la UI lo muestre
    }
  }

  Future<Map<String, dynamic>?> getGameDetails(int gameId) async {
    try {
      return await _igdbService.getGameById(gameId);
    } catch (e) {
      print('Error getGameDetails: $e');
      return null;
    }
  }

  Future<bool> testConnection() async {
    try {
      final results = await _igdbService.searchGames('Mario');
      return results.isNotEmpty;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}