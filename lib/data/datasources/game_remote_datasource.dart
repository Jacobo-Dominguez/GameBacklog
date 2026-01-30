import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../domain/entities/game_search_result.dart';

class GameRemoteDataSource {
  final http.Client client;

  GameRemoteDataSource({http.Client? client}) : client = client ?? http.Client();

  /// Buscar juegos por nombre
  Future<List<GameSearchResult>> searchGames(String query) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.gamesEndpoint}').replace(
        queryParameters: {
          'key': ApiConfig.apiKey,
          'search': query,
          'page_size': ApiConfig.pageSize.toString(),
          'ordering': ApiConfig.ordering,
        },
      );

      final response = await client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;
        
        return results
            .map((json) => GameSearchResult.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('API Key inválida. Por favor, configura tu API key en api_config.dart');
      } else {
        throw Exception('Error al buscar juegos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener detalles de un juego específico
  Future<GameSearchResult?> getGameDetails(int gameId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.gameDetailEndpoint}/$gameId').replace(
        queryParameters: {
          'key': ApiConfig.apiKey,
        },
      );

      final response = await client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GameSearchResult.fromJson(data as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Obtener juegos populares
  Future<List<GameSearchResult>> getPopularGames({int page = 1}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.gamesEndpoint}').replace(
        queryParameters: {
          'key': ApiConfig.apiKey,
          'page': page.toString(),
          'page_size': ApiConfig.pageSize.toString(),
          'ordering': ApiConfig.ordering,
        },
      );

      final response = await client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;
        
        return results
            .map((json) => GameSearchResult.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Error al obtener juegos populares: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Verificar conectividad con la API
  Future<bool> testConnection() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.gamesEndpoint}').replace(
        queryParameters: {
          'key': ApiConfig.apiKey,
          'page_size': '1',
        },
      );

      final response = await client.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
