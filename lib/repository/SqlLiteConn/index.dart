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
        version: 1,
        onCreate: (db, version) async {
          await db.execute('PRAGMA foreign_keys = ON;');

          await db.execute('''
            CREATE TABLE music (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                url TEXT NOT NULL,
                imageUrl TEXT NOT NULL,
                songName TEXT NOT NULL,
                decoration TEXT NOT NULL
            );
          ''');

          await db.execute('''
            CREATE TABLE favorite_music (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                musicId INTEGER NOT NULL,
                FOREIGN KEY (musicId) REFERENCES music(id)
                ON DELETE CASCADE
                ON UPDATE CASCADE
            );
          ''');
        },
      );

      _database = db;
      _completer.complete(db);
    } catch (e) {
      _completer.completeError(e);
    }
  }
}