import '../../domain/entities/game_session.dart';

class GameSessionModel extends GameSession {
  GameSessionModel({
    required super.id,
    required super.gameId,
    required super.userId,
    required super.sessionDate,
    required super.durationMinutes,
    super.description,
  });

  factory GameSessionModel.fromJson(Map<String, dynamic> json) {
    return GameSessionModel(
      id: json['id'],
      gameId: json['game_id'],
      userId: json['user_id'],
      sessionDate: DateTime.parse(json['session_date']),
      durationMinutes: json['duration_minutes'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game_id': gameId,
      'user_id': userId,
      'session_date': sessionDate.toIso8601String(),
      'duration_minutes': durationMinutes,
      'description': description,
    };
  }
}
