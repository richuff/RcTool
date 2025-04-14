import 'package:path/path.dart';
import 'package:rctool/entity/Music.dart';
import 'package:sqflite/sqflite.dart';

class SqlLiteConn{
  static var database;

  static initState() async {
     database = openDatabase(
        join(await getDatabasesPath(), 'music.db'),

        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE music('
                'id INTEGER PRIMARY KEY,'
                'url TEXT NOT NULL,'
                'imageUrl TEXT NOT NULL,'
                'songName TEXT NOT NULL,'
                'decoration TEXT NOT NULL,'
                'isFavorite INTEGER NOT NULL);',
          );
        },
        //版本
        version: 1,
    );
  }

  static Future<void> insertMusic(Music music,dynamic db) async {
    // 获取数据库的引用
    await db.insert(
      'music',
      music.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  static Future<List<Music>> query() async{
    final db = await database;

    final List<Map<String, Object?>> musicList= await db.query(
      'music',
      limit: 30,
    );

    return [
      for (final {
        'url': url as String,
        'imageUrl': imageUrl as String,
        'songName':songName as String,
        'decoration':decoration as String,
        'isFavorite':isFavorite as int
      } in musicList)
        Music(url, imageUrl, songName, decoration,isFavorite == 1),
    ];
  }

  static Future<void> queryByUrlAndInsert(String url, String imageUrl, String songName, String decoration, bool isFavorite) async {
    Music music = Music(url, imageUrl, songName, decoration,isFavorite);

    final db = await database;

    final List<Map<String, Object?>> musicList= await db.query(
      'music',
      where: 'url = ?',
      whereArgs: [url],
    );

    if (musicList.isEmpty){
      insertMusic(music,db);
    }else if (musicList[0]['isFavorite'] != isFavorite){
      updateMusicByFavorite(music,musicList[0]['id'] as int);
    }
  }

  static Future<void> queryByUrlAndUpdateFav(String url, String imageUrl, String songName, String decoration, bool isFavorite) async {
    Music music = Music(url, imageUrl, songName, decoration,isFavorite);

    final db = await database;

    final List<Map<String, Object?>> musicList= await db.query(
      'music',
      where: 'url = ?',
      whereArgs: [url],
    );
    updateMusicByFavorite(music,musicList[0]['id'] as int);
  }

  static Future<List<Music>> queryByFavorite() async{
    final db = await database;

    final List<Map<String, Object?>> musicList= await db.query(
      'music',
      where: 'isFavorite = 1',
      limit: 30,
    );

    return [
      for (final {
      'url': url as String,
      'imageUrl': imageUrl as String,
      'songName':songName as String,
      'decoration':decoration as String,
      'isFavorite':isFavorite as int
      } in musicList)
        Music(url, imageUrl, songName, decoration,isFavorite == 1),
    ];
  }

  static void deleteByUrl(String url) async {
    final db = await database;

    await db.delete(
      'music',
      where: 'url = ?',
      whereArgs: [url],
    );
  }

  static void updateMusicByFavorite(Music music,int id) async {
    final db = await database;

    await db.update(
      'music',
      music.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static void updateMusicByUrl(Music music) async {
    final db = await database;

    await db.update(
      'music',
      music.toMap(),
      where: 'url = ?',
      whereArgs: [music.url],
    );
  }
}