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

    if (!_completer.isCompleted) {
      await _initDatabase();
    }

    return _completer.future;
  }

  static Future<void> _initDatabase() async {
    try {
      if (kIsWeb) {
        databaseFactory = databaseFactoryFfiWeb;
        print('Web 端初始化 databaseFactoryFfiWeb');
      } else if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        print('桌面端初始化 databaseFactoryFfi');
      }

      final db = await openDatabase(
        'music_database.db',
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            PRAGMA foreign_keys = ON;
          
            CREATE TABLE music (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                url TEXT NOT NULL,
                imageUrl TEXT NOT NULL,
                songName TEXT NOT NULL,
                decoration TEXT NOT NULL
            );
          
            CREATE TABLE favorite_music (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                musicId INTEGER NOT NULL,
                FOREIGN KEY (musicId) REFERENCES music(id)
                ON DELETE CASCADE
                ON UPDATE CASCADE
            );
          ''');
          print('music 表创建成功');
        },
        onOpen: (db) {
          print('数据库打开成功');
        },
      );

      // 赋值并完成初始化
      _database = db;
      _completer.complete(db);
    } catch (e) {
      print('数据库初始化失败：$e');
      // 初始化失败时，主动完成 completer 并抛异常，避免无限等待
      _completer.completeError(e);
      throw Exception('数据库初始化失败，请检查配置：$e');
    }
  }
}