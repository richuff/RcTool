import 'package:rctool/repository/SqlLiteConn/index.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/repository/entity/playlist.dart';
import 'package:sqflite/sqflite.dart';

class PlaylistConn {
  static Future<int> insertPlaylist(String name) async {
    final db = await SqlLiteConn.dataBase;
    return db.insert(
      'playlist',
      Playlist(null, name, DateTime.now().millisecondsSinceEpoch).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 名称是否已被占用（用于新建歌单时避免重名）。
  static Future<bool> existsByName(String name) async {
    final db = await SqlLiteConn.dataBase;
    final rows = await db.query(
      'playlist',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Future<int> ensurePlaylist(String name) async {
    final db = await SqlLiteConn.dataBase;
    final rows = await db.query(
      'playlist',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.first['id'] as int;
    return insertPlaylist(name);
  }

  static Future<List<Playlist>> queryPlaylists() async {
    final db = await SqlLiteConn.dataBase;
    final rows = await db.rawQuery('''
      SELECT p.id, p.name, p.createdAt, COUNT(pm.musicId) AS musicCount
      FROM playlist p
      LEFT JOIN playlist_music pm ON pm.playlistId = p.id
      GROUP BY p.id
      ORDER BY p.createdAt DESC
    ''');

    return [
      for (final row in rows)
        Playlist(
          row['id'] as int,
          row['name'] as String,
          row['createdAt'] as int,
          musicCount: row['musicCount'] as int,
        ),
    ];
  }

  static Future<void> deletePlaylist(int playlistId) async {
    final db = await SqlLiteConn.dataBase;
    await db.delete(
      'playlist',
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  static Future<void> addMusic(int playlistId, int musicId) async {
    final db = await SqlLiteConn.dataBase;
    final count = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM playlist_music WHERE playlistId = ?',
          [playlistId],
        )) ??
        0;

    await db.insert(
      'playlist_music',
      {
        'playlistId': playlistId,
        'musicId': musicId,
        'sortOrder': count,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> replaceMusicList(
      int playlistId, List<Music> musicList) async {
    final db = await SqlLiteConn.dataBase;
    await db.delete(
      'playlist_music',
      where: 'playlistId = ?',
      whereArgs: [playlistId],
    );
    for (int i = 0; i < musicList.length; i++) {
      final musicId = musicList[i].id;
      if (musicId == null) continue;
      await db.insert(
        'playlist_music',
        {
          'playlistId': playlistId,
          'musicId': musicId,
          'sortOrder': i,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  static Future<void> removeMusic(int playlistId, int musicId) async {
    final db = await SqlLiteConn.dataBase;
    await db.delete(
      'playlist_music',
      where: 'playlistId = ? AND musicId = ?',
      whereArgs: [playlistId, musicId],
    );
  }

  /// 歌单内拖动排序后，按当前展示顺序重写 sortOrder。
  static Future<void> saveMusicOrder(int playlistId, List<int> musicIds) async {
    final db = await SqlLiteConn.dataBase;
    final batch = db.batch();
    for (int i = 0; i < musicIds.length; i++) {
      batch.update(
        'playlist_music',
        {'sortOrder': i},
        where: 'playlistId = ? AND musicId = ?',
        whereArgs: [playlistId, musicIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  /// 这首歌当前被哪些歌单收录（用于「…」菜单里显示勾选状态）。
  static Future<Set<int>> queryPlaylistIdsOfMusic(int musicId) async {
    final db = await SqlLiteConn.dataBase;
    final rows = await db.query(
      'playlist_music',
      columns: ['playlistId'],
      where: 'musicId = ?',
      whereArgs: [musicId],
    );
    return {
      for (final row in rows) row['playlistId'] as int,
    };
  }

  static Future<List<Music>> queryMusicByPlaylist(int playlistId) async {
    final db = await SqlLiteConn.dataBase;
    final rows = await db.rawQuery('''
      SELECT m.id, m.url, m.imageUrl, m.songName, m.decoration
      FROM playlist_music pm
      INNER JOIN music m ON m.id = pm.musicId
      WHERE pm.playlistId = ?
      ORDER BY pm.sortOrder ASC, pm.id ASC
    ''', [playlistId]);

    return [
      for (final row in rows)
        Music(
          row['id'] as int,
          row['url'] as String,
          row['imageUrl'] as String,
          row['songName'] as String,
          row['decoration'] as String,
        ),
    ];
  }

  static Future<void> insertFavoritePlaylist(int playlistId) async {
    final db = await SqlLiteConn.dataBase;
    await db.insert(
      'favorite_playlist',
      {'playlistId': playlistId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> deleteFavoritePlaylist(int playlistId) async {
    final db = await SqlLiteConn.dataBase;
    await db.delete(
      'favorite_playlist',
      where: 'playlistId = ?',
      whereArgs: [playlistId],
    );
  }

  static Future<bool> queryByPlaylistAndCheckFavorite(int playlistId) async {
    final db = await SqlLiteConn.dataBase;
    final rows = await db.query(
      'favorite_playlist',
      where: 'playlistId = ?',
      whereArgs: [playlistId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Future<List<Playlist>> queryFavoritePlaylists() async {
    final db = await SqlLiteConn.dataBase;
    final rows = await db.rawQuery('''
      SELECT p.id, p.name, p.createdAt, COUNT(pm.musicId) AS musicCount
      FROM favorite_playlist fp
      INNER JOIN playlist p ON p.id = fp.playlistId
      LEFT JOIN playlist_music pm ON pm.playlistId = p.id
      GROUP BY p.id
      ORDER BY fp.id DESC
    ''');

    return [
      for (final row in rows)
        Playlist(
          row['id'] as int,
          row['name'] as String,
          row['createdAt'] as int,
          musicCount: row['musicCount'] as int,
        ),
    ];
  }
}
