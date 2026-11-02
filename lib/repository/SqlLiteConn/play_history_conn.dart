import 'package:sqflite/sqflite.dart';

import '../entity/Music.dart';
import '../entity/play_history.dart';
import 'index.dart';

/// 播放历史与统计数据访问层。
class PlayHistoryConn {
  /// 几秒内对同一首歌的重复触发（双击、耳机重连、缓存就绪后又起播一次）
  /// 只当作同一次播放，避免「最近播放」里出现两条一模一样的记录。
  static const int duplicateWindowMs = 5000;

  /// 最近播放列表的查询语句：同一首歌只保留最近一次播放。
  /// 抽成常量方便回归用例直接在内存库里跑。
  static const String recentQuery = '''
      SELECT id, url, imageUrl, songName, decoration,
             MAX(playedAt) AS playedAt
      FROM play_history
      GROUP BY url
      ORDER BY playedAt DESC
      LIMIT ?
      ''';

  /// 距上次播放是否近到可以视为同一次播放。
  static bool isDuplicatePlay(int lastPlayedAtMs, int nowMs) {
    return nowMs - lastPlayedAtMs <= duplicateWindowMs;
  }

  static Future<void> record(Music music) async {
    if (music.url.isEmpty) return;
    final db = await SqlLiteConn.dataBase;
    final now = DateTime.now().millisecondsSinceEpoch;

    final recent = await db.query(
      'play_history',
      columns: ['id', 'playedAt'],
      where: 'url = ?',
      whereArgs: [music.url],
      orderBy: 'playedAt DESC',
      limit: 1,
    );
    if (recent.isNotEmpty) {
      final lastAt = recent.first['playedAt'] as int? ?? 0;
      if (isDuplicatePlay(lastAt, now)) {
        await db.update(
          'play_history',
          {
            'imageUrl': music.imageUrl,
            'songName': music.songName,
            'decoration': music.decoration,
            'playedAt': now,
          },
          where: 'id = ?',
          whereArgs: [recent.first['id']],
        );
        return;
      }
    }

    await db.insert('play_history', {
      'url': music.url,
      'imageUrl': music.imageUrl,
      'songName': music.songName,
      'decoration': music.decoration,
      'playedAt': now,
    });
  }

  /// 最近播放列表：同一首歌只保留最近一次，多次播放不会重复占位。
  static Future<List<PlayHistory>> queryRecent({int limit = 200}) async {
    final db = await SqlLiteConn.dataBase;
    final rows = await db.rawQuery(recentQuery, [limit]);
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

  /// 列表里一行代表一首歌，删除时连同它更早的播放记录一起清掉，
  /// 否则删掉最新一条后这首歌会带着旧时间又冒出来。
  static Future<void> deleteByUrl(String url) async {
    if (url.isEmpty) return;
    final db = await SqlLiteConn.dataBase;
    await db.delete('play_history', where: 'url = ?', whereArgs: [url]);
  }

  static Future<void> clear() async {
    final db = await SqlLiteConn.dataBase;
    await db.delete('play_history');
  }
}
