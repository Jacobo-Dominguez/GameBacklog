import 'package:flutter/foundation.dart';
import '../../domain/entities/community_review.dart';
import '../../data/datasources/community_local_datasource.dart';

class CommunityProvider with ChangeNotifier {
  final CommunityLocalDataSource dataSource;
  final String currentUserId;

  List<CommunityReview> _feed = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 5;

  List<CommunityReview> get feed => _feed;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  CommunityProvider({
    required this.dataSource,
    required this.currentUserId,
  }) {
    loadDiscoveryFeed();
  }

  Future<void> loadDiscoveryFeed() async {
    _isLoading = true;
    _currentPage = 0;
    _hasMore = true;
    notifyListeners();

    try {
      final results = await dataSource.getDiscoveryFeed(currentUserId, limit: _pageSize, offset: 0);
      _feed = List<CommunityReview>.from(results);
      if (_feed.length < _pageSize) {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Error loading community feed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreDiscoveryFeed() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final more = await dataSource.getDiscoveryFeed(
        currentUserId, 
        limit: _pageSize, 
        offset: _currentPage * _pageSize
      );
      
      if (more.isEmpty) {
        _hasMore = false;
      } else {
        _feed.addAll(List<CommunityReview>.from(more));
        if (more.length < _pageSize) {
          _hasMore = false;
        }
      }
    } catch (e) {
      debugPrint('Error loading more community feed: $e');
      _currentPage--;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<List<CommunityReview>> getReviewsForGame(String gameId) async {
    try {
      return await dataSource.getReviewsByGameId(gameId, currentUserId);
    } catch (e) {
      debugPrint('Error fetching game reviews: $e');
      return [];
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
