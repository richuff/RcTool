import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rctool/widget/app_scaffold.dart';
import '../../components/MusicListCP/music_choose_list.dart';

class MusicChoose extends StatelessWidget {
  const MusicChoose({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
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
