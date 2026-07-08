import 'package:rctool/repository/SqlLiteConn/index.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/repository/entity/recommend_history.dart';
import 'package:sqflite/sqflite.dart';

class RecommendHistoryConn {
  static Future<int> ensureHistory(String date) async {
    final db = await SqlLiteConn.dataBase;
    final rows = await db.query(
      'recommend_history',
      where: 'recommendDate = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.first['id'] as int;

    return db.insert(
      'recommend_history',
      {
        'recommendDate': date,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> saveHistory(String date, List<Music> musicList) async {
    final db = await SqlLiteConn.dataBase;
    final historyId = await ensureHistory(date);

    for (int i = 0; i < musicList.length; i++) {
      final musicId = musicList[i].id;
      if (musicId == null) continue;
      await db.insert(
        'recommend_history_music',
        {
          'historyId': historyId,
          'musicId': musicId,
          'sortOrder': i,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  static Future<List<RecommendHistory>> queryHistories() async {
    final db = await SqlLiteConn.dataBase;
    final rows = await db.rawQuery('''
      SELECT h.id, h.recommendDate, h.createdAt, COUNT(hm.musicId) AS musicCount
      FROM recommend_history h
      LEFT JOIN recommend_history_music hm ON hm.historyId = h.id
      GROUP BY h.id
      ORDER BY h.recommendDate DESC
    ''');

    return [
      for (final row in rows)
        RecommendHistory(
          row['id'] as int,
          row['recommendDate'] as String,
          row['createdAt'] as int,
          musicCount: row['musicCount'] as int,
        ),
    ];
  }

  static Future<List<Music>> queryMusicByHistory(int historyId) async {
    final db = await SqlLiteConn.dataBase;
    final rows = await db.rawQuery('''
      SELECT m.id, m.url, m.imageUrl, m.songName, m.decoration
      FROM recommend_history_music hm
      INNER JOIN music m ON m.id = hm.musicId
      WHERE hm.historyId = ?
      ORDER BY hm.sortOrder ASC, hm.id ASC
    ''', [historyId]);

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
