import 'package:rctool/repository/SqlLiteConn/index.dart';
import 'package:rctool/repository/entity/music_old.dart';
import 'package:sqflite/sqflite.dart';

import '../entity/Music.dart';



class MusicConn {
  static Future<Database> get _db async => await SqlLiteConn.Database;

  static Future<void> insertMusic(Music music, dynamic db) async {
    await db.insert(
      'music',
      music.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Music>> queryAll() async {
    final db = await _db;

    final List<Map<String, Object?>> musicList = await db.query(
      'music',
      limit: 30,
    );

    return [
      for (final {
      'url': url as String,
      'imageUrl': imageUrl as String,
      'songName': songName as String,
      'decoration': decoration as String,
      } in musicList)
        Music(url, imageUrl, songName, decoration),
    ];
  }

  static Future<void> updateMusicByUrl(Music music) async {
    final db = await _db;

    await db.update(
      'music',
      music.toMap(),
      where: 'url = ?',
      whereArgs: [music.url],
    );
  }

  static Future<void> deleteByUrl(String url) async {
    final db = await _db;

    await db.delete(
      'music',
      where: 'url = ?',
      whereArgs: [url],
    );
  }

  @Deprecated("废除isFavorite字段")
  static Future<List<MusicOld>> query() async {
    final db = await _db;

    final List<Map<String, Object?>> musicList = await db.query(
      'music',
      limit: 30,
    );

    return [
      for (final {
      'url': url as String,
      'imageUrl': imageUrl as String,
      'songName': songName as String,
      'decoration': decoration as String,
      'isFavorite': isFavorite as int
      } in musicList)
        MusicOld(url, imageUrl, songName, decoration, isFavorite == 1),
    ];
  }

  @Deprecated("废除isFavorite字段")
  static Future<void> insertMusicOld(MusicOld music, dynamic db) async {
    await db.insert(
      'music',
      music.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @Deprecated("废除isFavorite字段")
  static Future<void> queryByUrlAndInsert(
      String url,
      String imageUrl,
      String songName,
      String decoration,
      bool isFavorite,
      ) async {
    MusicOld music = MusicOld(url, imageUrl, songName, decoration, isFavorite);
    final db = await _db;

    final List<Map<String, Object?>> musicList = await db.query(
      'music',
      where: 'url = ?',
      whereArgs: [url],
    );

    if (musicList.isEmpty) {
      insertMusicOld(music, db);
    } else if (musicList[0]['isFavorite'] != isFavorite) {
      updateMusicByFavorite(music, musicList[0]['id'] as int);
    }
  }

  @Deprecated("采用喜欢音乐表进行存储")
  static Future<void> queryByUrlAndUpdateFav(
      String url,
      String imageUrl,
      String songName,
      String decoration,
      bool isFavorite,
      ) async {
    MusicOld music = MusicOld(url, imageUrl, songName, decoration, isFavorite);
    final db = await _db;

    final List<Map<String, Object?>> musicList = await db.query(
      'music',
      where: 'url = ?',
      whereArgs: [url],
    );
    updateMusicByFavorite(music, musicList[0]['id'] as int);
  }

  @Deprecated("废除isFavorite字段")
  static Future<List<MusicOld>> queryByFavorite() async {
    final db = await _db;

    final List<Map<String, Object?>> musicList = await db.query(
      'music',
      where: 'isFavorite = 1',
      limit: 30,
    );

    return [
      for (final {
      'url': url as String,
      'imageUrl': imageUrl as String,
      'songName': songName as String,
      'decoration': decoration as String,
      'isFavorite': isFavorite as int
      } in musicList)
        MusicOld(url, imageUrl, songName, decoration, isFavorite == 1),
    ];
  }

  @Deprecated("采用喜欢音乐表进行存储")
  static Future<void> updateMusicByFavorite(MusicOld music, int id) async {
    final db = await _db;

    await db.update(
      'music',
      music.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}