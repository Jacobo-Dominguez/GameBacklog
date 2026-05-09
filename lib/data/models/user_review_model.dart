import '../../domain/entities/user_review.dart';

class UserReviewModel extends UserReview {
  UserReviewModel({
    required super.id,
    required super.userId,
    required super.gameId,
    super.title,
    super.content,
    super.rating,
    super.isSpoiler,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserReviewModel.fromJson(Map<String, dynamic> json) {
    return UserReviewModel(
      id: json['id'],
      userId: json['user_id'],
      gameId: json['game_id'],
      title: json['title'],
      content: json['content'],
      rating: json['rating'],
      isSpoiler: json['is_spoiler'] == true || json['is_spoiler'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'game_id': gameId,
      'title': title,
      'content': content,
      'rating': rating,
      'is_spoiler': isSpoiler,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
