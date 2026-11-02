import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rctool/widget/BackGround/back_ground_enum.dart';
import '../../components/MusicListCP/music_like_list.dart';
import '../../feature/design/icon_button_no_ripple.dart';
import '../../widget/main_drawer.dart';
import '../../widget/search_widget.dart';

class MusicLike extends StatefulWidget {
  const MusicLike({super.key});

  @override
  State<MusicLike> createState() => _MusicLike();
}

class _MusicLike extends State<MusicLike> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      key: scaffoldKey,
      drawerScrimColor: Colors.transparent,
      drawer: MainDrawer((){
        scaffoldKey.currentState?.closeDrawer();
      }),
      appBar: AppBar(
          backgroundColor: scheme.surface,
          leading: Builder(builder: (context) {
            return Column(children: [
              const Padding(padding: EdgeInsets.only(top: 8)),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: IconButtonNoRipple(
                  hoverColor: scheme.primaryContainer,
                  focusColor: scheme.primaryContainer,
                  highlightColor: scheme.secondaryContainer,
                  alignment: Alignment.bottomCenter,
                  icon: const Icon(
                    Icons.menu,
                    size: 26,
                  ),
                  color: scheme.onSurface,
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            ]);
          }),
          actions: const [SearchWidget()]),
      body: Container(
          width: double.infinity,
          decoration: BackGroundEnum.musicBackGround.decoration,
          child: Column(children: [
            Flexible(
                child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false, dragDevices: {
                      //必须设置此事件，不然无法滚动
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    }),
                    child: const MusicLikeList())),
          ])),
    );
  }
}
