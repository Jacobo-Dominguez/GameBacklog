import 'package:flutter/foundation.dart';
import '../../domain/entities/community_review.dart';
import '../../data/datasources/community_local_datasource.dart';

class CommunityProvider with ChangeNotifier {
  final CommunityLocalDataSource dataSource;
  final String currentUserId;

  List<CommunityReview> _feed = [];
  bool _isLoading = false;

  List<CommunityReview> get feed => _feed;
  bool get isLoading => _isLoading;

  CommunityProvider({
    required this.dataSource,
    required this.currentUserId,
  }) {
    loadDiscoveryFeed();
  }

  Future<void> loadDiscoveryFeed() async {
    _isLoading = true;
    notifyListeners();

    try {
      _feed = await dataSource.getDiscoveryFeed(currentUserId);
    } catch (e) {
      debugPrint('Error loading community feed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String reviewId) async {
    try {
      // Optimizacion optimista
      final index = _feed.indexWhere((r) => r.reviewId == reviewId);
      if (index != -1) {
        final review = _feed[index];
        final isLiked = !review.isLikedByMe;
        final count = isLiked ? review.likesCount + 1 : review.likesCount - 1;
        
        _feed[index] = CommunityReview(
          reviewId: review.reviewId,
          userId: review.userId,
          username: review.username,
          userAvatarUrl: review.userAvatarUrl,
          gameId: review.gameId,
          gameTitle: review.gameTitle,
          gameCoverUrl: review.gameCoverUrl,
          reviewTitle: review.reviewTitle,
          notes: review.notes,
          rating: review.rating,
          isSpoiler: review.isSpoiler,
          addedDate: review.addedDate,
          likesCount: count,
          isLikedByMe: isLiked,
        );
        notifyListeners();
      }

      await dataSource.toggleLike(currentUserId, reviewId);
    } catch (e) {
      debugPrint('Error toggling like: $e');
      // Podríamos revertir el cambio optimista aquí si falla
    }
  }
}
