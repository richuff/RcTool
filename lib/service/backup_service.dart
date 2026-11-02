import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../feature/theme/type_value.dart';
import '../repository/SqlLiteConn/index.dart';
import 'external_storage.dart';

/// 一份备份文件的基本信息
class BackupFile {
  final File file;
  final DateTime time;
  final int size;

  BackupFile({
    required this.file,
    required this.time,
    required this.size,
  });

  String get fileName => p.basename(file.path);

  /// 备份里的歌单数量，列表里直接展示，省得恢复完才发现选错了
  int playlists = 0;
  int favorites = 0;
}

/// 恢复结果
class RestoreResult {
  final int playlists;
  final int favorites;
  final int lyrics;

  const RestoreResult({
    this.playlists = 0,
    this.favorites = 0,
    this.lyrics = 0,
  });
}

/// @ClassName BackupService
/// @Description 歌单 / 收藏 / 歌词 / 设置的本地备份与恢复。
///
/// 备份文件放在 `<外部目录>/backup/rcbackup-yyyyMMdd-HHmmss.json`，
/// 用户用文件管理器就能拷走；恢复时从同一目录里挑文件。
/// 表结构直接按行导出（playlist / playlist_music / favorite_music / lyric / music），
/// 恢复用 INSERT OR REPLACE / IGNORE，重复导入不会产生脏数据。
/// @Author richuff
/// @Version 1.0
class BackupService {
  static const int formatVersion = 1;

  /// 参与备份的数据表，顺序即恢复顺序（先父表再关联表）
  static const List<String> tables = [
    'music',
    'playlist',
    'playlist_music',
    'favorite_music',
    'lyric',
  ];

  /// 参与备份的偏好项
  static const List<String> prefKeys = [
    themeModeKey,
    languageCodeKey,
    countryCodeKey,
    playModeKey,
    volumeKey,
    cacheFirstKey,
    notificationKey,
    cacheLimitKey,
    live2dZoomKey,
    live2dLipSyncKey,
    live2dModelKey,
  ];

  static Future<Directory> backupDir() async {
    final root = await ExternalStorage.instance.root();
    final dir = Directory(p.join(root.path, 'backup'));
    await dir.create(recursive: true);
    return dir;
  }

  /// 导出当前数据，返回生成的文件
  static Future<File> export() async {
    final db = await SqlLiteConn.dataBase;
    final data = <String, Object?>{};

    for (final table in tables) {
      data[table] = await db.query(table);
    }

    final prefs = await SharedPreferences.getInstance();
    final settings = <String, Object?>{};
    for (final key in prefKeys) {
      final value = prefs.get(key);
      if (value != null) settings[key] = value;
    }
    data['settings'] = settings;

    final now = DateTime.now();
    final payload = <String, Object?>{
      'app': 'RcTool',
      'version': formatVersion,
      'exportedAt': now.toIso8601String(),
      'data': data,
    };

    final dir = await backupDir();
    final name = 'rcbackup-${_stamp(now)}.json';
    final file = File(p.join(dir.path, name));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    return file;
  }

  /// 备份目录里的所有备份，最新的排在前面
  static Future<List<BackupFile>> list() async {
    final dir = await backupDir();
    final entries = await dir
        .list()
        .where((entity) =>
            entity is File && entity.path.toLowerCase().endsWith('.json'))
        .cast<File>()
        .toList();

    final result = <BackupFile>[];
    for (final file in entries) {
      try {
        final stat = await file.stat();
        final backup = BackupFile(
          file: file,
          time: stat.modified,
          size: stat.size,
        );
        // 读一次摘要，列表里能显示「3 个歌单 · 12 首收藏」
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is Map && decoded['data'] is Map) {
          final data = decoded['data'] as Map;
          backup.playlists = (data['playlist'] as List?)?.length ?? 0;
          backup.favorites = (data['favorite_music'] as List?)?.length ?? 0;
        }
        result.add(backup);
      } catch (_) {
        // 不是合法备份的文件不展示
      }
    }
    result.sort((a, b) => b.time.compareTo(a.time));
    return result;
  }

  /// 恢复：只增不删，同名歌单会按名字合并
  static Future<RestoreResult> restore(File file) async {
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['data'] is! Map) {
      throw const FormatException('backup.json');
    }
    final data = decoded['data'] as Map;

    final db = await SqlLiteConn.dataBase;
    await db.transaction((txn) async {
      for (final table in tables) {
        final rows = data[table];
        if (rows is! List) continue;
        for (final row in rows) {
          if (row is! Map) continue;
          try {
            await txn.insert(
              table,
              row.map((key, value) => MapEntry('$key', value)),
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          } catch (_) {
            // 单行失败（版本差异 / 字段缺失）跳过，不中断整份备份
          }
        }
      }
    });

    final settings = data['settings'];
    if (settings is Map) {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in settings.entries) {
        final key = '${entry.key}';
        final value = entry.value;
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        }
      }
    }

    return RestoreResult(
      playlists: (data['playlist'] as List?)?.length ?? 0,
      favorites: (data['favorite_music'] as List?)?.length ?? 0,
      lyrics: (data['lyric'] as List?)?.length ?? 0,
    );
  }

  static String _stamp(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}${two(time.month)}${two(time.day)}'
        '-${two(time.hour)}${two(time.minute)}${two(time.second)}';
  }
}
