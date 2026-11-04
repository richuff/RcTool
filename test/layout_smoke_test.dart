import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/locale_controller.dart';
import 'package:rctool/controller/wallpaper_controller.dart';
import 'package:rctool/repository/SqlLiteConn/play_history_conn.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/service/live2d_model_library.dart';
import 'package:rctool/utils/lrc_parser.dart';
import 'package:rctool/utils/my_message.dart';
import 'package:rctool/widget/play_all_button.dart';
import 'package:rctool/widget/song_row.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 轻量布局冒烟测试：确认新组件在常见尺寸下不会溢出、
/// 点击区域能正常触发，以及 LRC 解析的边界行为。
Widget _host(Widget child, {double width = 360}) {
  return GetMaterialApp(
    translations: MyMessage(),
    locale: const Locale('zh', 'CN'),
    fallbackLocale: const Locale('zh', 'CN'),
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('PlayAllButton 在窄屏与 AppBar 中都不溢出', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_host(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Spacer(),
              PlayAllButton(dense: true, onPressed: () => tapped++),
            ],
          ),
          const SizedBox(height: 12),
          PlayAllButton(count: 12, onPressed: () => tapped++),
          const SizedBox(height: 12),
          PlayAllButton(count: 12, onPressed: null),
        ],
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(PlayAllButton).first, warnIfMissed: false);
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('SongRow 常规态 / 播放态 / 缓存态都不溢出', (tester) async {
    final music = Music(1, 'https://example.com/a.flac', '', 'Constant Moderato',
        'Blue Archive');
    await tester.pumpWidget(_host(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SongRow(music: music, onPlayToggle: () {}, onMore: () {}),
          SongRow(
            music: music,
            playing: true,
            loading: true,
            index: 0,
            onPlayToggle: () {},
            onRemove: () {},
            onMore: () {},
          ),
          SongRow(
            music: music,
            subtitle: '3.20 MB · 已下载',
            onPlayToggle: () {},
          ),
        ],
      ),
    ));
    // 缓存态里有无限循环的进度指示器，这里只等一帧
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  test('LRC 解析支持多时间戳、元信息与偏移', () {
    const raw = '''
[ti:Test Song]
[ar:Someone]
[offset:500]
[00:01.00][00:05.50]第一句
[00:10.20]第二句
没有时间戳的一行
''';
    final sheet = LyricSheet.parse(raw);
    expect(sheet.tags['ti'], 'Test Song');
    expect(sheet.offset.inMilliseconds, 500);
    expect(sheet.synced, isTrue);
    expect(sheet.lines.length, 3);
    expect(sheet.lines.first.time.inMilliseconds, 1000);
    expect(sheet.lines[1].time.inMilliseconds, 5500);
    // 1000 + offset 500 = 1500 生效时间
    expect(sheet.indexAt(const Duration(milliseconds: 1200)), 0);
    expect(sheet.indexAt(const Duration(milliseconds: 6500)), 1);
  });

  test('Live2D 模型 id 可还原为可加载的站点路径', () {
    expect(Live2DModelLibrary.entryFromId(Live2DModelLibrary.builtInId).builtIn,
        isTrue);
    final entry = Live2DModelLibrary.entryFromId('ext:Haru/Haru.model3.json');
    expect(entry.name, 'Haru');
    expect(entry.modelPath, '/ext/Haru/Haru.model3.json');
    expect(entry.builtIn, isFalse);

    // 找不到保存的 id 时回退到列表第一个（内置 Haru）
    final resolved = Live2DModelLibrary.resolve(
      const [Live2DModelLibrary.builtIn],
      'ext:gone/model.model3.json',
    );
    expect(resolved.id, Live2DModelLibrary.builtInId);
  });

  test('纯文本歌词按顺序保留但不作为同步歌词', () {
    final sheet = LyricSheet.parse('第一行\n第二行');
    expect(sheet.synced, isFalse);
    expect(sheet.lines.length, 2);
    expect(sheet.indexAt(const Duration(seconds: 3)), 0);
  });

  test('三套语言包的键完全一致且没有空值', () {
    final keys = MyMessage().keys;
    final zh = keys['zh_CN']!;
    final ja = keys['ja_JP']!;
    final en = keys['en_US']!;

    expect(zh.length, greaterThan(300));
    expect(ja.keys.toSet(), zh.keys.toSet());
    expect(en.keys.toSet(), zh.keys.toSet());
    for (final map in [zh, ja, en]) {
      for (final entry in map.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: entry.key);
      }
    }
  });

  test('切歌语言后 tr 结果跟着变', () {
    Get.addTranslations(MyMessage().keys);
    Get.locale = const Locale('zh', 'CN');
    expect('播放全部'.tr, '播放全部');
    Get.locale = const Locale('en', 'US');
    expect('播放全部'.tr, isNot('播放全部'));
    expect('播放全部'.tr.toLowerCase(), contains('play'));
    Get.locale = const Locale('ja', 'JP');
    expect('播放全部'.tr, 'すべて再生');
    // 带占位符的文案在每种语言下都能替换
    Get.locale = const Locale('en', 'US');
    expect('队列 @count 首'.trParams({'count': '3'}), contains('3'));
  });

  testWidgets('切换 LocaleController 后界面文案立即跟着变', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = Get.put(LocaleController());

    await tester.pumpWidget(
      Obx(
        () => GetMaterialApp(
          translations: MyMessage(),
          locale: controller.locale.value,
          fallbackLocale: const Locale('zh', 'CN'),
          home: Builder(
            builder: (_) => Scaffold(body: Center(child: Text('播放全部'.tr))),
          ),
        ),
      ),
    );
    expect(find.text('播放全部'), findsOneWidget);

    await controller.change(const Locale('en', 'US'));
    await tester.pumpAndSettle();
    expect(find.text('播放全部'), findsNothing);
    expect(Get.locale?.languageCode, 'en');

    await controller.change(const Locale('ja', 'JP'));
    await tester.pumpAndSettle();
    expect(find.text('すべて再生'), findsOneWidget);

    Get.reset();
  });

  test('播放队列可以完整写入与还原（断点续播）', () {
    final music =
        Music(7, 'https://example.com/a.mp3', 'cover.jpg', '歌名', '歌手');
    final restored = Music.fromJson(jsonDecode(jsonEncode(music.toJson())));
    expect(restored, isNotNull);
    expect(restored!.id, 7);
    expect(restored.url, music.url);
    expect(restored.songName, '歌名');
    expect(restored.decoration, '歌手');
    // 坏数据直接丢弃，不会污染队列
    expect(Music.fromJson({'songName': 'no url'}), isNull);
    expect(Music.fromJson('nope'), isNull);
  });

  test('最近播放按歌曲去重，同一首歌只留最近一次', () async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(':memory:');
    addTearDown(db.close);
    await db.execute('''
      CREATE TABLE play_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        songName TEXT NOT NULL,
        decoration TEXT NOT NULL,
        playedAt INTEGER NOT NULL
      )
    ''');

    Future<void> add(String url, String name, int at) {
      return db.insert('play_history', {
        'url': url,
        'imageUrl': 'cover.jpg',
        'songName': name,
        'decoration': '',
        'playedAt': at,
      });
    }

    await add('a.mp3', 'A 第一次', 1000);
    await add('b.mp3', 'B', 2000);
    await add('a.mp3', 'A 第三次', 3000);
    await add('a.mp3', 'A 第二次', 2500); // 乱序写入也要取时间最大的那条

    final rows = await db.rawQuery(PlayHistoryConn.recentQuery, [200]);
    expect(rows.length, 2, reason: '同一首歌只占一行');
    expect(rows.first['url'], 'a.mp3');
    expect(rows.first['songName'], 'A 第三次');
    expect(rows.last['url'], 'b.mp3');
  });

  test('同一首歌几秒内重复触发视为同一次播放', () {
    const now = 1000000;
    expect(PlayHistoryConn.isDuplicatePlay(now - 300, now), isTrue);
    expect(PlayHistoryConn.isDuplicatePlay(now - 5000, now), isTrue);
    expect(PlayHistoryConn.isDuplicatePlay(now - 5001, now), isFalse);
  });

  test('壁纸文件名映射到页面槽位', () {
    expect(WallpaperController.slotOfFile('home'), 'home');
    expect(WallpaperController.slotOfFile('home-1700000000'), 'home');
    expect(WallpaperController.slotOfFile('live2d-1'), 'live2d');
    expect(WallpaperController.slotOfFile('music'), 'music');
    expect(WallpaperController.slotOfFile('about-old'), 'about');
    expect(WallpaperController.slotOfFile('default'), 'default');
    expect(WallpaperController.slotOfFile('default-42'), 'default');
    // 前缀相近但不同槽位的文件名不应该被误吞
    expect(WallpaperController.slotOfFile('homeland'), isNull);
    expect(WallpaperController.slotOfFile('aboutme-1'), isNull);
  });

  test('同一个槽位有多张图时取最新一张', () {
    final t0 = DateTime(2026, 11, 4, 10);
    final chosen = WallpaperController.pickSlots([
      MapEntry('home', t0),
      MapEntry('home-100', t0.add(const Duration(minutes: 5))),
      MapEntry('home-50', t0.add(const Duration(minutes: 2))),
      MapEntry('music', t0),
      MapEntry('random', t0.add(const Duration(hours: 1))),
    ]);
    expect(chosen['home'], 'home-100');
    expect(chosen['music'], 'music');
    expect(chosen.containsKey('random'), isFalse);
  });

  test('只认图片扩展名', () {
    expect(WallpaperController.isSupportedFile('/x/home.jpg'), isTrue);
    expect(WallpaperController.isSupportedFile('/x/home.PNG'), isTrue);
    expect(WallpaperController.isSupportedFile('/x/home.webp'), isTrue);
    expect(WallpaperController.isSupportedFile('/x/home.gif'), isFalse);
    expect(WallpaperController.isSupportedFile('/x/home'), isFalse);
  });
}
