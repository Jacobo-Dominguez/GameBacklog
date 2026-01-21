class GameBacklogEntry {
  final String id;
  final String userId;
  final String gameId;
  final String status;
  final int hoursPlayed;
  final int? rating;
  final String? notes;
  final DateTime addedDate;
  final DateTime? completedDate;
  final DateTime lastUpdated;

  GameBacklogEntry({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.status,
    this.hoursPlayed = 0,
    this.rating,
    this.notes,
    required this.addedDate,
    this.completedDate,
    required this.lastUpdated,
  });
}
