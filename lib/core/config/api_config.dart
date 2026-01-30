class ApiConfig {
  // RAWG API Configuration
  static const String baseUrl = 'https://api.rawg.io/api';
  
  // API Key - IMPORTANTE: Obtener en https://rawg.io/apidocs
  // Para desarrollo, puedes usar esta key de prueba (limitada)
  // RECOMENDADO: Crear tu propia cuenta y obtener tu API key
  static const String apiKey = '906fbecebf7c429080a673e9922b45dd';
  
  // Endpoints
  static const String gamesEndpoint = '/games';
  static const String gameDetailEndpoint = '/games';
  
  // Parámetros comunes
  static const int pageSize = 20;
  static const String ordering = '-rating';
}
