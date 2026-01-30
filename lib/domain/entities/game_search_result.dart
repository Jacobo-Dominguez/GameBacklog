class GameSearchResult {
  final int id;
  final String name;
  final String? backgroundImage;
  final double? rating;
  final List<String> platforms;
  final List<String> genres;
  final String? released;
  final String? description; // ✅ AGREGADO - RAWG lo devuelve en búsquedas

  GameSearchResult({
    required this.id,
    required this.name,
    this.backgroundImage,
    this.rating,
    required this.platforms,
    required this.genres,
    this.released,
    this.description, // ✅ AGREGADO
  });

  factory GameSearchResult.fromJson(Map<String, dynamic> json) {
    return GameSearchResult(
      id: json['id'] as int,
      name: json['name'] as String,
      backgroundImage: json['background_image'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      platforms: (json['platforms'] as List<dynamic>?)
              ?.map((p) => p['platform']['name'] as String)
              .toList() ??
          [],
      genres: (json['genres'] as List<dynamic>?)
              ?.map((g) => g['name'] as String)
              .toList() ??
          [],
      released: json['released'] as String?,
      description: json['description'] as String?, // ✅ Mapeado desde RAWG
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'background_image': backgroundImage,
      'rating': rating,
      'platforms': platforms,
      'genres': genres,
      'released': released,
      'description': description, // ✅ Incluido
    };
  }
}