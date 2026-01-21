import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import 'database_helper.dart';
import 'user_local_datasource.dart';

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final DatabaseHelper dbHelper;

  UserLocalDataSourceImpl(this.dbHelper);

  @override
  Future<UserModel?> getUserById(String id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isNotEmpty) {
      return UserModel.fromJson(result.first);
    }
    return null;
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    
    if (result.isNotEmpty) {
      return UserModel.fromJson(result.first);
    }
    return null;
  }

  @override
  Future<UserModel?> getUserByUsername(String username) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    
    if (result.isNotEmpty) {
      return UserModel.fromJson(result.first);
    }
    return null;
  }

  @override
  Future<void> insertUser(UserModel user) async {
    final db = await dbHelper.database;
    await db.insert(
      'users',
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateUser(UserModel user) async {
    final db = await dbHelper.database;
    await db.update(
      'users',
      user.toJson(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  @override
  Future<void> deleteUser(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
