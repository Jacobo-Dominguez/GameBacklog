import '../../domain/entities/game.dart';

class GameModel extends Game {
  GameModel({
    required super.id,
    required super.title,
    super.coverUrl,
    super.description,
    super.platform,
    super.genre,
    super.releaseYear,
    required super.createdAt,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'],
      title: json['title'],
      coverUrl: json['cover_url'],
      description: json['description'],
      platform: json['platform'],
      genre: json['genre'],
      releaseYear: json['release_year'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cover_url': coverUrl,
      'description': description,
      'platform': platform,
      'genre': genre,
      'release_year': releaseYear,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
