class GameBacklogEntry {
  final String id;
  final String userId;
  final String gameId;
  final String status;
  final int hoursPlayed;
  final int? rating;
  final String? notes;
  final bool isFavorite; // ✅ Nuevo
  final String? reviewTitle; // ✅ Nuevo
  final bool isSpoiler; // ✅ Nuevo
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
    this.isFavorite = false,
    this.reviewTitle,
    this.isSpoiler = false,
    required this.addedDate,
    this.completedDate,
    required this.lastUpdated,
  });
}
