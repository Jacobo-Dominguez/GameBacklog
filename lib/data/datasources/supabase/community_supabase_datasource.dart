import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../../models/community_review_model.dart';

class CommunitySupabaseDataSource {
  final SupabaseClient _client;

  CommunitySupabaseDataSource(this._client);

  Future<List<CommunityReviewModel>> getDiscoveryFeed(String currentUserId, {int limit = 10, int offset = 0}) async {
    final result = await _client.rpc('get_discovery_feed', params: {
      'p_user_id': currentUserId,
      'p_limit': limit,
      'p_offset': offset,
    });

    debugPrint('DEBUG: Discovery feed returned ${(result as List).length} items');
    return (result).map((json) => CommunityReviewModel.fromJson(json)).toList();
  }

  Future<List<CommunityReviewModel>> getReviewsByGameId(String gameId, String currentUserId) async {
    debugPrint('DEBUG: Fetching community reviews for game: $gameId (current user: $currentUserId)');

    final result = await _client.rpc('get_reviews_by_game', params: {
      'p_game_id': gameId,
      'p_user_id': currentUserId,
    });

    debugPrint('DEBUG: Found ${(result as List).length} community reviews');
    return (result).map((json) => CommunityReviewModel.fromJson(json)).toList();
  }

  Future<bool> toggleLike(String userId, String reviewId) async {
    final existing = await _client
        .from('review_likes')
        .select('id')
        .eq('user_id', userId)
        .eq('review_id', reviewId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('review_likes')
          .delete()
          .eq('user_id', userId)
          .eq('review_id', reviewId);
      return false;
    } else {
      await _client.from('review_likes').insert({
        'id': const Uuid().v4(),
        'user_id': userId,
        'review_id': reviewId,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    }
  }
}
