import '../../domain/entities/game_backlog_entry.dart';

class GameBacklogModel extends GameBacklogEntry {
  GameBacklogModel({
    required super.id,
    required super.userId,
    required super.gameId,
    required super.status,
    super.hoursPlayed,
    super.rating,
    super.notes,
    required super.addedDate,
    super.completedDate,
    required super.lastUpdated,
  });

  factory GameBacklogModel.fromJson(Map<String, dynamic> json) {
    return GameBacklogModel(
      id: json['id'],
      userId: json['user_id'],
      gameId: json['game_id'],
      status: json['status'],
      hoursPlayed: json['hours_played'] ?? 0,
      rating: json['rating'],
      notes: json['notes'],
      addedDate: DateTime.parse(json['added_date']),
      completedDate: json['completed_date'] != null
          ? DateTime.parse(json['completed_date'])
          : null,
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'game_id': gameId,
      'status': status,
      'hours_played': hoursPlayed,
      'rating': rating,
      'notes': notes,
      'added_date': addedDate.toIso8601String(),
      'completed_date': completedDate?.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
