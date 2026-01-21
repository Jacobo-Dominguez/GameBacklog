class Game {
  final String id;
  final String title;
  final String? coverUrl;
  final String? description;
  final String? platform;
  final String? genre;
  final int? releaseYear;
  final DateTime createdAt;

  Game({
    required this.id,
    required this.title,
    this.coverUrl,
    this.description,
    this.platform,
    this.genre,
    this.releaseYear,
    required this.createdAt,
  });
}
