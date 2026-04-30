import '../../domain/entities/community_review.dart';

class CommunityReviewModel extends CommunityReview {
  CommunityReviewModel({
    required super.reviewId,
    required super.userId,
    required super.username,
    super.userAvatarUrl,
    required super.gameId,
    required super.gameTitle,
    super.gameCoverUrl,
    super.reviewTitle,
    required super.notes,
    super.rating,
    required super.isSpoiler,
    required super.addedDate,
    required super.likesCount,
    required super.isLikedByMe,
  });

  factory CommunityReviewModel.fromJson(Map<String, dynamic> json) {
    return CommunityReviewModel(
      reviewId: json['review_id'],
      userId: json['user_id'],
      username: json['username'],
      userAvatarUrl: json['user_avatar_url'],
      gameId: json['game_id'],
      gameTitle: json['game_title'],
      gameCoverUrl: json['game_cover_url'],
      reviewTitle: json['review_title'],
      notes: json['notes'],
      rating: json['rating'],
      isSpoiler: json['is_spoiler'] == 1,
      addedDate: DateTime.parse(json['added_date']),
      likesCount: json['likes_count'] ?? 0,
      isLikedByMe: json['is_liked_by_me'] == 1,
    );
  }
}
