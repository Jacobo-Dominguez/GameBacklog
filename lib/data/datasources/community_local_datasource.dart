import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/community_review_model.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class CommunityLocalDataSource {
  final DatabaseHelper dbHelper;

  CommunityLocalDataSource(this.dbHelper);

  Future<List<CommunityReviewModel>> getDiscoveryFeed(String currentUserId, {int limit = 10, int offset = 0}) async {
    final db = await dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT 
        ur.id as review_id,
        ur.title as review_title,
        ur.content as notes,
        ur.rating,
        ur.is_spoiler,
        ur.created_at as added_date,
        u.id as user_id,
        u.username,
        u.avatar_url as user_avatar_url,
        g.id as game_id,
        g.title as game_title,
        g.coverUrl as game_cover_url,
        (SELECT COUNT(*) FROM review_likes rl WHERE rl.review_id = ur.id) as likes_count,
        (SELECT COUNT(*) FROM review_likes rl2 WHERE rl2.review_id = ur.id AND rl2.user_id = ?) as is_liked_by_me
      FROM user_reviews ur
      INNER JOIN users u ON ur.user_id = u.id
      LEFT JOIN games g ON ur.game_id = g.id
      WHERE ur.user_id != ? AND ur.content IS NOT NULL AND ur.content != ''
      ORDER BY ur.created_at DESC
      LIMIT ? OFFSET ?
    ''', [currentUserId, currentUserId, limit, offset]);

    return result.map((json) => CommunityReviewModel.fromJson(json)).toList();
  }

  Future<List<CommunityReviewModel>> getReviewsByGameId(String gameId, String currentUserId) async {
    final db = await dbHelper.database;
    
    debugPrint('DEBUG: Fetching community reviews for game: $gameId (current user: $currentUserId)');

    final result = await db.rawQuery('''
      SELECT 
        ur.id as review_id,
        ur.title as review_title,
        ur.content as notes,
        ur.rating,
        ur.is_spoiler,
        ur.created_at as added_date,
        u.id as user_id,
        u.username,
        u.avatar_url as user_avatar_url,
        g.id as game_id,
        g.title as game_title,
        g.coverUrl as game_cover_url,
        (SELECT COUNT(*) FROM review_likes rl WHERE rl.review_id = ur.id) as likes_count,
        (SELECT COUNT(*) FROM review_likes rl2 WHERE rl2.review_id = ur.id AND rl2.user_id = ?) as is_liked_by_me
      FROM user_reviews ur
      INNER JOIN users u ON ur.user_id = u.id
      LEFT JOIN games g ON ur.game_id = g.id
      WHERE ur.game_id = ? AND ur.user_id != ? AND ur.content IS NOT NULL AND ur.content != ''
      ORDER BY ur.created_at DESC
    ''', [currentUserId, gameId, currentUserId]);

    debugPrint('DEBUG: Found ${result.length} community reviews');
    
    return result.map((json) => CommunityReviewModel.fromJson(json)).toList();
  }

  Future<bool> toggleLike(String userId, String reviewId) async {
    final db = await dbHelper.database;
    
    final existing = await db.query(
      'review_likes',
      where: 'user_id = ? AND review_id = ?',
      whereArgs: [userId, reviewId],
    );

    if (existing.isNotEmpty) {
      await db.delete(
        'review_likes',
        where: 'user_id = ? AND review_id = ?',
        whereArgs: [userId, reviewId],
      );
      return false; 
    } else {
      await db.insert(
        'review_likes',
        {
          'id': const Uuid().v4(),
          'user_id': userId,
          'review_id': reviewId,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      return true; 
    }
  }
}
