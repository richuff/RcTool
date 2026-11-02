import 'package:rctool/repository/SqlLiteConn/index.dart';
import 'package:rctool/repository/entity/music_old.dart';
import 'package:sqflite/sqflite.dart';

import '../entity/Music.dart';



class MusicConn {

  static Future<int> insertMusic(Music music) async {
    final db = await SqlLiteConn.dataBase;
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
    final db = await SqlLiteConn.dataBase;

    // 以音频 url 作为唯一标识去重：
    // 同一首歌名可能对应不同音频，按 songName 去重会串音/覆盖；
    // 同一首歌改了歌名又会被当成新歌重复导入。url 才是稳定的唯一键。
    final List<Map<String, Object?>> existing = await db.query(
      'music',
      where: 'url = ?',
      whereArgs: [url],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      // 已存在则仅同步最新元数据（封面/歌名/描述），并复用原 id，避免产生重复行
      await db.update(
        'music',
        {
          'imageUrl': imageUrl,
          'songName': songName,
          'decoration': decoration,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return id;
    }

    // 不存在才插入，id 传 null 由数据库自增
    return insertMusic(Music(null, url, imageUrl, songName, decoration));
  }

  static Future<List<Music>> queryByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    final db = await SqlLiteConn.dataBase;

    // 生成占位符：?, ?, ?
    final placeholders = List.filled(ids.length, '?').join(',');

    final List<Map<String, Object?>> musicList = await db.query(
      'music',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
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
    final db = await SqlLiteConn.dataBase;

    // 查询全部歌曲，不再用 limit 截断，避免导入较多后被静默丢弃
    final List<Map<String, Object?>> musicList = await db.query('music');

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
    final db = await SqlLiteConn.dataBase;

    await db.update(
      'music',
      music.toMap(),
      where: 'url = ?',
      whereArgs: [music.url],
    );
  }

  static Future<void> deleteByUrl(String url) async {
    final db = await SqlLiteConn.dataBase;

    await db.delete(
      'music',
      where: 'url = ?',
      whereArgs: [url],
    );
  }

  @Deprecated("废除isFavorite字段")
  static Future<List<MusicOld>> query() async {
    final db = await SqlLiteConn.dataBase;

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
    final db = await SqlLiteConn.dataBase;

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
    final db = await SqlLiteConn.dataBase;

    final List<Map<String, Object?>> musicList = await db.query(
      'music',
      where: 'url = ?',
      whereArgs: [url],
    );
    updateMusicByFavorite(music, musicList[0]['id'] as int);
  }

  @Deprecated("废除isFavorite字段")
  static Future<List<MusicOld>> queryByFavorite() async {
    final db = await SqlLiteConn.dataBase;

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
    final db = await SqlLiteConn.dataBase;

    await db.update(
      'music',
      music.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
