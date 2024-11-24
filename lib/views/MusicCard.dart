import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../components/MSCard.dart';

class MusicCard extends StatefulWidget {
  const MusicCard({super.key});

  @override
  State<MusicCard> createState() => _MusicCard();
}

class _MusicCard extends State<MusicCard> {
  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MSCard(UrlSource(
              'https://m701.music.126.net/20241124135957/31db35f9f2a80baff2239bd656babb2f/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/28481680626/8c3f/dd57/4c1c/84333f57c88a35512dd3ba34a1a1816f.mp3'),const NetworkImage("https://img.meituan.net/csc/d05518606ba7064dd445508e3cf3d4c42860983.png")),
          MSCard(UrlSource(
              'https://m701.music.126.net/20241124142010/ccd00dd89c268cc177266fd934f50487/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/14096444542/bafc/a068/39f8/9a9e06e5634410b5e7e81df24749e656.mp3'),const NetworkImage("https://img.meituan.net/csc/d05518606ba7064dd445508e3cf3d4c42860983.png")),
          MSCard(UrlSource(
              'https://m801.music.126.net/20241124142419/a29f4caa3fde69a4ea7ae48028003afa/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/19844359355/66d6/a1ef/0101/f93fb43c55e05a273e01e0acb03add41.mp3'),const NetworkImage("https://img.meituan.net/csc/d05518606ba7064dd445508e3cf3d4c42860983.png")),
        ]);
  }
}
