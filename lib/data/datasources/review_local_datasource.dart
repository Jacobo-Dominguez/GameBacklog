import 'database_helper.dart';
import '../models/user_review_model.dart';
import '../../domain/entities/user_review.dart';

class ReviewLocalDataSource {
  final DatabaseHelper dbHelper;

  ReviewLocalDataSource(this.dbHelper);

  Future<void> insertReview(UserReviewModel review) async {
    final db = await dbHelper.database;
    await db.insert('user_reviews', review.toJson());
  }

  Future<List<UserReview>> getReviewsByGameId(String gameId, String userId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_reviews',
      where: 'game_id = ? AND user_id = ?',
      whereArgs: [gameId, userId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return UserReviewModel.fromJson(maps[i]);
    });
  }

  Future<void> updateReview(UserReviewModel review) async {
    final db = await dbHelper.database;
    await db.update(
      'user_reviews',
      review.toJson(),
      where: 'id = ?',
      whereArgs: [review.id],
    );
  }

  Future<void> deleteReview(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      'user_reviews',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<UserReview>> getAllReviewsByUserId(String userId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_reviews',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return UserReviewModel.fromJson(maps[i]);
    });
  }
}
