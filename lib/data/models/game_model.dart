import '../../domain/entities/game.dart';

class GameModel extends Game {
  GameModel({
    required super.id,
    required super.title,
    super.platform,
    super.genre,
    super.releaseDate,
    super.coverUrl,
    super.description,
    super.remoteId,
    required super.createdAt,
    required super.updatedAt,
    required super.userId,
  });

  // Constructor from JSON (Supabase/PostgreSQL - snake_case)
  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'],
      title: json['title'],
      platform: json['platform'],
      genre: json['genre'],
      releaseDate: json['release_date'] != null
          ? DateTime.tryParse(json['release_date'])
          : null,
      coverUrl: json['cover_url'],
      description: json['description'],
      remoteId: json['remote_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      userId: json['user_id'] ?? 'unknown',
    );
  }

  // To JSON (Supabase/PostgreSQL - snake_case)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'platform': platform,
      'genre': genre,
      'release_date': releaseDate?.toIso8601String(),
      'cover_url': coverUrl,
      'description': description,
      'remote_id': remoteId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
    };
  }
}
