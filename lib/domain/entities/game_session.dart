class GameSession {
  final String id;
  final String gameId;
  final String userId;
  final DateTime sessionDate;
  final int durationMinutes;
  final String? description;

  GameSession({
    required this.id,
    required this.gameId,
    required this.userId,
    required this.sessionDate,
    required this.durationMinutes,
    this.description,
  });
}
