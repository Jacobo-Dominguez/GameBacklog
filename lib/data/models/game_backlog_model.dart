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
    super.isFavorite,
    super.reviewTitle,
    super.isSpoiler,
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
      isFavorite: (json['is_favorite'] ?? 0) == 1,
      reviewTitle: json['review_title'],
      isSpoiler: (json['is_spoiler'] ?? 0) == 1,
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
      'is_favorite': isFavorite ? 1 : 0,
      'review_title': reviewTitle,
      'is_spoiler': isSpoiler ? 1 : 0,
      'added_date': addedDate.toIso8601String(),
      'completed_date': completedDate?.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
