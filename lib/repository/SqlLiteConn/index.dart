import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class SqlLiteConn {
  static Database? _database;
  static final Completer<Database> _completer = Completer<Database>();

  static Future<Database> get dataBase async {
    if (_database != null) return _database!;
    if (!_completer.isCompleted) await _initDatabase();
    return _completer.future;
  }

  static Future<void> _initDatabase() async {
    try {
      if (kIsWeb) {
        databaseFactory = databaseFactoryFfiWeb;
      } else if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final db = await openDatabase(
        'music_database.db',
        version: 5,
        // 外键是连接级会话设置，不会持久化，必须在每次打开连接时设置
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          await _createTables(db);
        },
        // 升级安装后旧库文件仍在，onCreate 不会执行；
        // 这里用 IF NOT EXISTS 给老库补建缺失的表
        onUpgrade: (db, oldVersion, newVersion) async {
          await _createTables(db);
        },
      );

      _database = db;
      _completer.complete(db);
    } catch (e) {
      _completer.completeError(e);
    }
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS music (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          url TEXT NOT NULL,
          imageUrl TEXT NOT NULL,
          songName TEXT NOT NULL,
          decoration TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorite_music (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          musicId INTEGER NOT NULL,
          FOREIGN KEY (musicId) REFERENCES music(id)
          ON DELETE CASCADE
          ON UPDATE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlist (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          createdAt INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlist_music (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          playlistId INTEGER NOT NULL,
          musicId INTEGER NOT NULL,
          sortOrder INTEGER NOT NULL,
          UNIQUE(playlistId, musicId),
          FOREIGN KEY (playlistId) REFERENCES playlist(id)
          ON DELETE CASCADE
          ON UPDATE CASCADE,
          FOREIGN KEY (musicId) REFERENCES music(id)
          ON DELETE CASCADE
          ON UPDATE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorite_playlist (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          playlistId INTEGER NOT NULL UNIQUE,
          FOREIGN KEY (playlistId) REFERENCES playlist(id)
          ON DELETE CASCADE
          ON UPDATE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS recommend_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          recommendDate TEXT NOT NULL UNIQUE,
          createdAt INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS recommend_history_music (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          historyId INTEGER NOT NULL,
          musicId INTEGER NOT NULL,
          sortOrder INTEGER NOT NULL,
          UNIQUE(historyId, musicId),
          FOREIGN KEY (historyId) REFERENCES recommend_history(id)
          ON DELETE CASCADE
          ON UPDATE CASCADE,
          FOREIGN KEY (musicId) REFERENCES music(id)
          ON DELETE CASCADE
          ON UPDATE CASCADE
      );
    ''');
  }
}
