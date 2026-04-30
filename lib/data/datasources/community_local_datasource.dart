import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/community_review_model.dart';
import 'package:uuid/uuid.dart';

class CommunityLocalDataSource {
  final DatabaseHelper dbHelper;

  CommunityLocalDataSource(this.dbHelper);

  Future<List<CommunityReviewModel>> getDiscoveryFeed(String currentUserId) async {
    final db = await dbHelper.database;
    
    // We fetch backlog entries that have notes (reviews) and are NOT from the current user.
    // We join with users to get the reviewer info.
    // We join with games to get the game info.
    // We left join with review_likes to get the count and whether the current user liked it.
    final result = await db.rawQuery('''
      SELECT 
        gb.id as review_id,
        gb.review_title,
        gb.notes,
        gb.rating,
        gb.is_spoiler,
        gb.added_date,
        u.id as user_id,
        u.username,
        u.avatar_url as user_avatar_url,
        g.id as game_id,
        g.title as game_title,
        g.coverUrl as game_cover_url,
        (SELECT COUNT(*) FROM review_likes rl WHERE rl.review_id = gb.id) as likes_count,
        (SELECT COUNT(*) FROM review_likes rl2 WHERE rl2.review_id = gb.id AND rl2.user_id = ?) as is_liked_by_me
      FROM game_backlog gb
      INNER JOIN users u ON gb.user_id = u.id
      INNER JOIN games g ON gb.game_id = g.id
      WHERE gb.user_id != ? AND gb.notes IS NOT NULL AND gb.notes != ''
      ORDER BY gb.added_date DESC
    ''', [currentUserId, currentUserId]);

    return result.map((json) => CommunityReviewModel.fromJson(json)).toList();
  }

  Future<bool> toggleLike(String userId, String reviewId) async {
    final db = await dbHelper.database;
    
    // Comprobar si ya existe el like
    final existing = await db.query(
      'review_likes',
      where: 'user_id = ? AND review_id = ?',
      whereArgs: [userId, reviewId],
    );

    if (existing.isNotEmpty) {
      // Si existe, lo borramos (unlike)
      await db.delete(
        'review_likes',
        where: 'user_id = ? AND review_id = ?',
        whereArgs: [userId, reviewId],
      );
      return false; // Retorna false indicando que ya NO está likeado
    } else {
      // Si no existe, lo creamos (like)
      await db.insert(
        'review_likes',
        {
          'id': const Uuid().v4(),
          'user_id': userId,
          'review_id': reviewId,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      return true; // Retorna true indicando que AHORA está likeado
    }
  }
}
