import 'package:sqflite/sqflite.dart';

import '../entity/Music.dart';
import '../entity/play_history.dart';
import 'index.dart';

/// 播放历史与统计数据访问层。
class PlayHistoryConn {
  static Future<void> record(Music music) async {
    if (music.url.isEmpty) return;
    final db = await SqlLiteConn.dataBase;
    await db.insert('play_history', {
      'url': music.url,
      'imageUrl': music.imageUrl,
      'songName': music.songName,
      'decoration': music.decoration,
      'playedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<List<PlayHistory>> queryRecent({int limit = 200}) async {
    final db = await SqlLiteConn.dataBase;
    final rows = await db.query(
      'play_history',
      orderBy: 'playedAt DESC',
      limit: limit,
    );
    return rows.map(PlayHistory.fromMap).toList();
  }

  static Future<Map<String, int>> queryOverview() async {
    final db = await SqlLiteConn.dataBase;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day)
        .millisecondsSinceEpoch;

    final total = await db.rawQuery('SELECT COUNT(*) AS value FROM play_history');
    final unique =
        await db.rawQuery('SELECT COUNT(DISTINCT url) AS value FROM play_history');
    final today = await db.rawQuery(
      'SELECT COUNT(*) AS value FROM play_history WHERE playedAt >= ?',
      [todayStart],
    );

    return {
      'total': Sqflite.firstIntValue(total) ?? 0,
      'unique': Sqflite.firstIntValue(unique) ?? 0,
      'today': Sqflite.firstIntValue(today) ?? 0,
    };
  }

  static Future<List<PlayedSongSummary>> queryTopPlayed({int limit = 5}) async {
    final db = await SqlLiteConn.dataBase;
    final rows = await db.rawQuery(
      '''
      SELECT url, imageUrl, songName, decoration,
             COUNT(*) AS playCount, MAX(playedAt) AS lastPlayedAt
      FROM play_history
      GROUP BY url
      ORDER BY playCount DESC, lastPlayedAt DESC
      LIMIT ?
      ''',
      [limit],
    );

    return rows.map((row) {
      return PlayedSongSummary(
        music: Music(
          null,
          row['url'] as String,
          row['imageUrl'] as String,
          row['songName'] as String,
          row['decoration'] as String,
        ),
        playCount: row['playCount'] as int,
        lastPlayedAt:
            DateTime.fromMillisecondsSinceEpoch(row['lastPlayedAt'] as int),
      );
    }).toList();
  }

  static Future<List<DateTime>> queryPlayedAtSince(DateTime start) async {
    final db = await SqlLiteConn.dataBase;
    final rows = await db.query(
      'play_history',
      columns: ['playedAt'],
      where: 'playedAt >= ?',
      whereArgs: [start.millisecondsSinceEpoch],
      orderBy: 'playedAt ASC',
    );
    return rows
        .map((row) =>
            DateTime.fromMillisecondsSinceEpoch(row['playedAt'] as int))
        .toList();
  }

  static Future<void> delete(int id) async {
    final db = await SqlLiteConn.dataBase;
    await db.delete('play_history', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clear() async {
    final db = await SqlLiteConn.dataBase;
    await db.delete('play_history');
  }
}
