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

  // Constructor from JSON (Local Database - SQLite)
  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'],
      title: json['title'],
      platform: json['platform'],
      genre: json['genre'],
      releaseDate: json['releaseDate'] != null
          ? DateTime.tryParse(json['releaseDate'])
          : null,
      coverUrl: json['coverUrl'],
      description: json['description'],
      remoteId: json['remoteId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(), // Fallback for migration
      userId: json['userId'] ?? 'unknown', // Fallback for migration
    );
  }

  // To JSON (Local Database - SQLite)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'platform': platform,
      'genre': genre,
      'releaseDate': releaseDate?.toIso8601String(),
      'coverUrl': coverUrl,
      'description': description,
      'remoteId': remoteId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
    };
  }
}
