import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SqlLiteConn {
  static var dataBase;

  static initState() async {
    dataBase = openDatabase(
      join(await getDatabasesPath(), 'music.db'),

      onCreate: (db, version) {
        // 示例（你数据库创建时直接用）
        return db.execute('''
        PRAGMA foreign_keys = ON;
      
        CREATE TABLE music (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT NOT NULL,
            imageUrl TEXT NOT NULL,
            songName TEXT NOT NULL,
            decoration TEXT NOT NULL,
        );
      
        CREATE TABLE favorite_music (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            musicId INTEGER NOT NULL,
            FOREIGN KEY (musicId) REFERENCES music(id)
            ON DELETE CASCADE
            ON UPDATE CASCADE
        );
      ''');
      },
      //版本
      version: 1,
    );
  }
}
