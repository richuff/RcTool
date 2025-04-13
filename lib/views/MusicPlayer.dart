import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:rctool/controller/MusicController.dart';
import 'package:rctool/entity/Music.dart';

import '../components/MSCard.dart';
import '../components/MusicList.dart';
import '../components/MusicListCP/LeftToolBar.dart';
import '../components/MusicListCP/RightToolBar.dart';
import '../utils/SqlLiteConn/index.dart';

class MusicPlayer extends StatefulWidget {
  const MusicPlayer({super.key});

  @override
  State<MusicPlayer> createState() => _MusicCard();
}

class _MusicCard extends State<MusicPlayer> {
  MusicController musicController = Get.put(MusicController());

  List<Music> msList = [];
  bool isEmpty = true;

  updateList(){
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMusicList();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMusicList();
    });
    musicController.addListener(updateList);
  }

  Future<void> _loadMusicList() async {
    msList = await SqlLiteConn.query();
    setState(() {
      isEmpty = msList.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Column(children: [
      Flexible(
          flex: 2,
          child: Row(
            children: [
              const SizedBox(
                width: 10,
              ),
              const Flexible(flex: 4, child: LeftToolbar()),
              Flexible(
                flex: 1,
                child: RightToolbar(),
              )
            ],
          )),
      Flexible(
          flex: 6,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(scrollbars: false, dragDevices: {
              //必须设置此事件，不然无法滚动
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            }),
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: isEmpty
                            ? <Widget>[
                                const MSCard(
                                    "",
                                    "http://kycloud3.koyoo.cn/202503218399a202503212001341625.jpg",
                                    "未选择播放的歌曲",
                                    "",
                                    false)
                              ]
                            : msList.map((element) {
                                return MSCard(
                                    element.url,
                                    element.imageUrl,
                                    element.songName,
                                    element.decoration,
                                    element.isFavorite);
                              }).toList())
                  ],
                )),
          )),
      const MusicList()
    ]));
  }
}