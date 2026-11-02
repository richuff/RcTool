import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rctool/widget/app_scaffold.dart';
import '../../components/MusicListCP/music_choose_list.dart';

/// @ClassName MusicChoose
/// @Description 当前播放队列页面。
/// @Author richuff
/// @Version 2.0
class MusicChoose extends StatelessWidget {
  const MusicChoose({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '播放队列',
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          dragDevices: {
            // 必须设置此事件，不然桌面端无法拖拽滚动
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: MusicChooseList(),
      ),
    );
  }
}
