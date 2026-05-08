class UserReview {
  final String id;
  final String userId;
  final String gameId;
  final String? title;
  final String? content;
  final int? rating;
  final bool isSpoiler;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserReview({
    required this.id,
    required this.userId,
    required this.gameId,
    this.title,
    this.content,
    this.rating,
    this.isSpoiler = false,
    required this.createdAt,
    required this.updatedAt,
  });

  UserReview copyWith({
    String? title,
    String? content,
    int? rating,
    bool? isSpoiler,
    DateTime? updatedAt,
  }) {
    return UserReview(
      id: id,
      userId: userId,
      gameId: gameId,
      title: title ?? this.title,
      content: content ?? this.content,
      rating: rating ?? this.rating,
      isSpoiler: isSpoiler ?? this.isSpoiler,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
