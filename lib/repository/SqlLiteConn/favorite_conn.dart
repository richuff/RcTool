import 'package:rctool/repository/SqlLiteConn/music_conn.dart';
import 'package:sqflite/sqflite.dart';
import 'package:rctool/repository/SqlLiteConn/index.dart';

import '../entity/Music.dart';
import '../entity/favorite_music.dart';

class FavoriteConn{

  static Future<void> insertFavoriteMusic(int musicId) async {
    if (await queryByMusicAndCheckFavorite(musicId)) return;
    final db = await SqlLiteConn.dataBase;
    var favoriteMusic = FavoriteMusic(musicId: musicId);
    await db.insert(
      'favorite_music',
      favoriteMusic.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<bool> queryByMusicAndCheckFavorite(int musicId) async {
    final db = await SqlLiteConn.dataBase;

    final List<Map<String, Object?>> musicFavoriteList = await db.query(
      'favorite_music',
      where: 'musicId = ?',
      whereArgs: [musicId],
    );

    return musicFavoriteList.isNotEmpty;
  }

  static Future<List<Music>> queryFavoriteMusic() async {
    final db = await SqlLiteConn.dataBase;

    // 收藏歌曲不再用 limit 截断，并按收藏时间倒序（最近收藏排在前面）
    final List<Map<String, Object?>> favoriteMusicList = await db.query(
      'favorite_music',
      orderBy: 'id DESC',
    );
    List<int> musicIds = [];
    for (var map in favoriteMusicList) {
      int? musicId = int.tryParse(map['musicId'].toString());
      if (musicId != null) {
        musicIds.add(musicId);
      }
    }

    return MusicConn.queryByIds(musicIds);
  }

  static Future<void> updateByMusicId(FavoriteMusic favoriteMusic) async {
    final db = await SqlLiteConn.dataBase;

    await db.update(
      'favorite_music',
      favoriteMusic.toMap(),
      where: 'id = ?',
      whereArgs: [favoriteMusic.id],
    );
  }

  static Future<void> deleteByMusicId(int musicId) async {
    final db = await SqlLiteConn.dataBase;

    await db.delete(
      'favorite_music',
      where: 'musicId = ?',
      whereArgs: [musicId],
    );
  }
}
