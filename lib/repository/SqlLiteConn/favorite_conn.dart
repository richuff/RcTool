import 'package:rctool/repository/SqlLiteConn/music_conn.dart';
import 'package:sqflite/sqflite.dart';
import 'package:rctool/repository/SqlLiteConn/index.dart';

import '../entity/Music.dart';
import '../entity/favorite_music.dart';

class FavoriteConn{
  static Future<Database> get _db async => await SqlLiteConn.dataBase;

  static Future<void> insertFavoriteMusic(FavoriteMusic favoriteMusic, dynamic db) async {
    await db.insert(
      'favorite_music',
      favoriteMusic.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<bool> queryByMusicAndCheckFavorite(int id) async {
    final db = await _db;

    final List<Map<String, Object?>> musicFavoriteList = await db.query(
      'favorite_music',
      where: 'musicId = ?',
      whereArgs: [id],
    );

    return musicFavoriteList.isNotEmpty;
  }

  static Future<List<Music>> queryFavoriteMusic() async {
    final db = await _db;

    final List<Map<String, Object?>> favoriteMusicList = await db.query(
      'favorite_music',
      limit: 30,
    );
    List<int> ids = List.empty();
    for (final {'id': id as int} in favoriteMusicList){
      ids.add(id);
    }

    return MusicConn.queryByIds(ids);
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