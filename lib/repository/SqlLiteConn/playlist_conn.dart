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

  static Future<void> removeMusic(int playlistId, int musicId) async {
    final db = await SqlLiteConn.dataBase;
    await db.delete(
      'playlist_music',
      where: 'playlistId = ? AND musicId = ?',
      whereArgs: [playlistId, musicId],
    );
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
}
