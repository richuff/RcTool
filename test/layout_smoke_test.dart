import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/utils/lrc_parser.dart';
import 'package:rctool/utils/my_message.dart';
import 'package:rctool/widget/play_all_button.dart';
import 'package:rctool/widget/song_row.dart';

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

    await tester.tap(find.byType(PlayAllButton).first);
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

  test('纯文本歌词按顺序保留但不作为同步歌词', () {
    final sheet = LyricSheet.parse('第一行\n第二行');
    expect(sheet.synced, isFalse);
    expect(sheet.lines.length, 2);
    expect(sheet.indexAt(const Duration(seconds: 3)), 0);
  });
}
