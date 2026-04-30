import '../../domain/entities/game_list_item.dart';

class GameListItemModel extends GameListItem {
  GameListItemModel({
    required super.id,
    required super.listId,
    required super.gameId,
    required super.addedAt,
  });

  factory GameListItemModel.fromJson(Map<String, dynamic> json) {
    return GameListItemModel(
      id: json['id'],
      listId: json['list_id'],
      gameId: json['game_id'],
      addedAt: DateTime.parse(json['added_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'list_id': listId,
      'game_id': gameId,
      'added_at': addedAt.toIso8601String(),
    };
  }
}
