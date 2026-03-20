import 'package:rctool/repository/SqlLiteConn/index.dart';
import 'package:rctool/repository/entity/music_old.dart';
import 'package:sqflite/sqflite.dart';

import '../entity/Music.dart';



class MusicConn {
  static Future<Database> get _db async => await SqlLiteConn.dataBase;

  static Future<int> insertMusic(Music music, dynamic db) async {
    int insertId = await db.insert(
      'music',
      music.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return insertId;
  }

  static Future<int?> queryByNameAndInsertMusic(
      String url,
      String imageUrl,
      String songName,
      String decoration,
      ) async {
    // 关键：id 传 null，让数据库自动生成
    Music music = Music(null, url, imageUrl, songName, decoration);

    final db = await _db;

    final List<Map<String, Object?>> musicList = await db.query(
      'music',
      where: 'songName = ?',
      whereArgs: [songName],
    );

    if (musicList.isEmpty) {
      return await insertMusic(music, db);
    }
    return null;
  }

  static Future<List<Music>> queryByIds(List<int> ids) async {
    final db = await _db;

    // 生成占位符：?, ?, ?
    final placeholders = List.filled(ids.length, '?').join(',');

    final List<Map<String, Object?>> musicList = await db.query(
      'music',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
      limit: 30,
    );

    return [
      for (final {
      'id': id as int,
      'url': url as String,
      'imageUrl': imageUrl as String,
      'songName': songName as String,
      'decoration': decoration as String,
      } in musicList)
        Music(id,url, imageUrl, songName, decoration),
    ];
  }

  static Future<List<Music>> queryAll() async {
    final db = await _db;

    final List<Map<String, Object?>> musicList = await db.query(
      'music',
      limit: 30,
    );

    return [
      for (final {
      'id':id as int,
      'url': url as String,
      'imageUrl': imageUrl as String,
      'songName': songName as String,
      'decoration': decoration as String,
      } in musicList)
        Music(id,url, imageUrl, songName, decoration),
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