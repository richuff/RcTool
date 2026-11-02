import 'package:rctool/repository/SqlLiteConn/index.dart';
import 'package:rctool/repository/entity/lyric.dart';
import 'package:sqflite/sqflite.dart';

/// @ClassName LyricConn
/// @Description 歌词存储。以音频 url 为主键，因此同一首歌从曲库 / 歌单 / 历史
///              任意入口播放都能读到同一份歌词。
/// @Author richuff
/// @Version 1.0
class LyricConn {
  static Future<LyricRecord?> query(String url) async {
    if (url.isEmpty) return null;
    final db = await SqlLiteConn.dataBase;
    final rows = await db.query(
      'lyric',
      where: 'url = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return LyricRecord(
      url: row['url'] as String? ?? url,
      content: row['content'] as String? ?? '',
      offsetMs: (row['offsetMs'] as int?) ?? 0,
      updatedAt: (row['updatedAt'] as int?) ?? 0,
    );
  }

  static Future<void> save(
    String url,
    String content, {
    int? offsetMs,
  }) async {
    if (url.isEmpty) return;
    final db = await SqlLiteConn.dataBase;
    final existing = await query(url);
    final payload = {
      'url': url,
      'content': content,
      'offsetMs': offsetMs ?? existing?.offsetMs ?? 0,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await db.insert(
      'lyric',
      payload,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateOffset(String url, int offsetMs) async {
    if (url.isEmpty) return;
    final db = await SqlLiteConn.dataBase;
    await db.update(
      'lyric',
      {
        'offsetMs': offsetMs,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'url = ?',
      whereArgs: [url],
    );
  }

  static Future<void> delete(String url) async {
    final db = await SqlLiteConn.dataBase;
    await db.delete('lyric', where: 'url = ?', whereArgs: [url]);
  }

  static Future<int> count() async {
    final db = await SqlLiteConn.dataBase;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM lyric');
    return (rows.first['c'] as int?) ?? 0;
  }
}
