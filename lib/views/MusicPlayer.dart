import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rctool/components/MusicList.dart';

import '../components/MSCard.dart';

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
          child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MSCard(
                      UrlSource(
                          'https://m701.music.126.net/20241124135957/31db35f9f2a80baff2239bd656babb2f/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/28481680626/8c3f/dd57/4c1c/84333f57c88a35512dd3ba34a1a1816f.mp3'),
                      const NetworkImage(
                          "https://p0.meituan.net/csc/ac442b7297cabb92da0ad4f114b22660667771.jpg"),"1","2"),
                  MSCard(
                      UrlSource(
                          'https://m801.music.126.net/20241124151132/089a108ea57a50166bb9a18fd9fcca0b/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/21276391271/c58a/a410/696c/ff1b31ca4f753dc7e7e2afcf10898679.mp3'),
                      const NetworkImage(
                          "https://p0.meituan.net/csc/ac442b7297cabb92da0ad4f114b22660667771.jpg"),"TruE","黄龄"),
                  MSCard(
                      UrlSource(
                          'https://m801.music.126.net/20241124142419/a29f4caa3fde69a4ea7ae48028003afa/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/19844359355/66d6/a1ef/0101/f93fb43c55e05a273e01e0acb03add41.mp3'),
                      const NetworkImage(
                          "https://p0.meituan.net/csc/ac442b7297cabb92da0ad4f114b22660667771.jpg"),"水星记","郭顶"
                  ),
                ])
          ],
        ),
      )),
      const MusicList()
    ]));
  }
}
