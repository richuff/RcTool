import 'package:sqflite/sqflite.dart';
import 'package:rctool/repository/SqlLiteConn/index.dart';

import '../entity/favorite_music.dart';

class FavoriteConn{
  static Future<Database> get _db async => await SqlLiteConn.Database;

  static Future<void> insertFavoriteMusic(FavoriteMusic favoriteMusic, dynamic db) async {
    await db.insert(
      'favorite_music',
      favoriteMusic.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<FavoriteMusic>> query() async {
    final db = await _db;

    final List<Map<String, Object?>> favoriteMusicList = await db.query(
      'favorite_music',
      limit: 30,
    );

    return [
      for (final {
      'id': id as String,
      'musicId': musicId as String,
      } in favoriteMusicList)
        FavoriteMusic(id,musicId),
    ];
  }

  static Future<void> updateMusicByUrl(FavoriteMusic favoriteMusic) async {
    final db = await _db;

    await db.update(
      'favorite_music',
      favoriteMusic.toMap(),
      where: 'id = ?',
      whereArgs: [favoriteMusic.id],
    );
  }

  static Future<void> deleteByUrl(String id) async {
    final db = await _db;

    await db.delete(
      'favorite_music',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}