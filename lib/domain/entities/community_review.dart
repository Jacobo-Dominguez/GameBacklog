class CommunityReview {
  final String reviewId;
  final String userId;
  final String username;
  final String? userAvatarUrl;
  
  final String gameId;
  final String gameTitle;
  final String? gameCoverUrl;
  
  final String? reviewTitle;
  final String notes;
  final int? rating;
  final bool isSpoiler;
  final DateTime addedDate;
  
  final int likesCount;
  final bool isLikedByMe;

  CommunityReview({
    required this.reviewId,
    required this.userId,
    required this.username,
    this.userAvatarUrl,
    required this.gameId,
    required this.gameTitle,
    this.gameCoverUrl,
    this.reviewTitle,
    required this.notes,
    this.rating,
    required this.isSpoiler,
    required this.addedDate,
    required this.likesCount,
    required this.isLikedByMe,
  });
}
