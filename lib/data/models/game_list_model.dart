import '../../domain/entities/game_list.dart';

class GameListModel extends GameList {
  GameListModel({
    required super.id,
    required super.userId,
    required super.name,
    super.description,
    required super.createdAt,
    required super.updatedAt,
  });

  factory GameListModel.fromJson(Map<String, dynamic> json) {
    return GameListModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
