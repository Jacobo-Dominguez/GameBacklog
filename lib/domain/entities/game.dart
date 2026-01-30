class Game {
  final String id;
  final String title; // Added back, as it's in the constructor and methods
  final String? platform; // Added back, as it's in the constructor and methods
  final String? genre;
  final DateTime? releaseDate;
  final String? coverUrl; // URL de la portada
  final String? description; // Descripción del juego
  final int? remoteId; // ID en RAWG
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;

  Game({
    required this.id,
    required this.title,
    this.platform,
    this.genre,
    this.releaseDate,
    this.coverUrl,
    this.description,
    this.remoteId,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
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

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'],
      title: map['title'],
      platform: map['platform'],
      genre: map['genre'],
      releaseDate: map['releaseDate'] != null
          ? DateTime.parse(map['releaseDate'])
          : null,
      coverUrl: map['coverUrl'],
      description: map['description'],
      remoteId: map['remoteId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      userId: map['userId'],
    );
  }
}
