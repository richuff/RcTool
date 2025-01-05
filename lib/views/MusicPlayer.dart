import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/MSCard.dart';
import '../components/MusicList.dart';
import '../entity/MusicList.dart';

class MusicPlayer extends StatefulWidget {
  const MusicPlayer({super.key});

  @override
  State<MusicPlayer> createState() => _MusicCard();
}

class _MusicCard extends State<MusicPlayer> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Column(children: [
      Flexible(
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
                    children: allmusiclist.map((element) {
                      return MSCard(element["url"]!, element["imageUrl"]!,
                          element["songName"]!, element["decoration"]!);
                    }).toList())
              ],
            )),
      )),
      const MusicList()
    ]));
  }
}
