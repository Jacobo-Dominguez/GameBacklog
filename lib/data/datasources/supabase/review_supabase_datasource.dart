import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_review_model.dart';
import '../../../domain/entities/user_review.dart';

class ReviewSupabaseDataSource {
  final SupabaseClient _client;

  ReviewSupabaseDataSource(this._client);

  Future<void> insertReview(UserReviewModel review) async {
    await _client.from('user_reviews').insert(review.toJson());
  }

  Future<List<UserReview>> getReviewsByGameId(String gameId, String userId) async {
    final result = await _client
        .from('user_reviews')
        .select()
        .eq('game_id', gameId)
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (result as List).map((json) => UserReviewModel.fromJson(json)).toList();
  }

  Future<void> updateReview(UserReviewModel review) async {
    await _client.from('user_reviews').update(review.toJson()).eq('id', review.id);
  }

  Future<void> deleteReview(String id) async {
    await _client.from('user_reviews').delete().eq('id', id);
  }

  Future<List<UserReview>> getAllReviewsByUserId(String userId) async {
    final result = await _client
        .from('user_reviews')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (result as List).map((json) => UserReviewModel.fromJson(json)).toList();
  }
}
