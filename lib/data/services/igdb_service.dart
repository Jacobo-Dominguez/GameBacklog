import 'dart:convert';
import 'package:http/http.dart' as http;

class IGDBService {
  // ✅ Tus credenciales reales (ya las tienes configuradas correctamente)
  static const String clientId = 'mndb5tj9brc1f5r95johlwccuu63is';
  static const String clientSecret = '6lk5tgmng7ldc087ehedgoj6ynapzh';
  
  static String? _accessToken;
  static DateTime? _tokenExpiry;

  Future<String> _getAccessToken() async {
    if (_accessToken != null && _tokenExpiry != null && _tokenExpiry!.isAfter(DateTime.now())) {
      return _accessToken!;
    }

    // ✅ URL CORREGIDA: SIN ESPACIOS
    final response = await http.post(
      Uri.parse('https://id.twitch.tv/oauth2/token'), // ✅ SIN ESPACIOS
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'grant_type': 'client_credentials',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _accessToken = data['access_token'];
      _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
      return _accessToken!;
    } else {
      throw Exception('Error IGDB token: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> searchGames(String query) async {
    final token = await _getAccessToken();
    
    if (query.trim().isEmpty) return [];

    // ✅ URL CORREGIDA: SIN ESPACIOS
    final response = await http.post(
      Uri.parse('https://api.igdb.com/v4/games'), // ✅ SIN ESPACIOS
      headers: {
        'Client-ID': clientId,
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'text/plain', // ✅ Requerido por IGDB
      },
      body: 'search "$query"; fields name, slug, summary, storyline, platforms.name, genres.name, first_release_date, cover.url, screenshots.url, involved_companies.company.name, rating, aggregated_rating, total_rating; limit 20;',
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Error IGDB: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map<String, dynamic>?> getGameById(int id) async {
    final token = await _getAccessToken();

    // ✅ URL CORREGIDA: SIN ESPACIOS
    final response = await http.post(
      Uri.parse('https://api.igdb.com/v4/games'), // ✅ SIN ESPACIOS
      headers: {
        'Client-ID': clientId,
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: 'fields name, slug, summary, storyline, platforms.name, genres.name, first_release_date, cover.url, screenshots.url, involved_companies.company.name, rating, aggregated_rating, total_rating, websites.url, websites.category; where id = $id;',
    );

    if (response.statusCode == 200) {
      final List results = json.decode(response.body);
      if (results.isNotEmpty) {
        return results.first as Map<String, dynamic>;
      }
      return null;
    } else {
      throw Exception('Error IGDB details: ${response.statusCode} ${response.body}');
    }
  }
}