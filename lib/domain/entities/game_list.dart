class GameList {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  GameList({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });
}
