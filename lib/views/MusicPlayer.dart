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
  List list = [
    {
      "url": "https://m801.music.126.net/20241124175624/1d04fa757f8e56578c2f5ea63369c5a4/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/34872778166/ac04/1c4a/f63c/1a7c179dea39ebe65fd62f034f2f804a.mp3",
      "imageUrl":
          "https://p0.meituan.net/csc/ac442b7297cabb92da0ad4f114b22660667771.jpg",
      "songName": "TruE",
      "decoration": "黄龄"
    },
    {
      "url": "https://m801.music.126.net/20241124175624/1d04fa757f8e56578c2f5ea63369c5a4/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/34872778166/ac04/1c4a/f63c/1a7c179dea39ebe65fd62f034f2f804a.mp3",
      "imageUrl":
      "https://p0.meituan.net/csc/ac442b7297cabb92da0ad4f114b22660667771.jpg",
      "songName": "TruE",
      "decoration": "黄龄"
    },
    {
      "url": "https://m801.music.126.net/20241124175624/1d04fa757f8e56578c2f5ea63369c5a4/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/34872778166/ac04/1c4a/f63c/1a7c179dea39ebe65fd62f034f2f804a.mp3",
      "imageUrl":
      "https://p0.meituan.net/csc/ac442b7297cabb92da0ad4f114b22660667771.jpg",
      "songName": "TruE",
      "decoration": "黄龄"
    }
  ];

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
                children: list.map((element) {
                  return MSCard(
                      UrlSource(element["url"]),
                      NetworkImage(element["imageUrl"]),
                      element["songName"],
                      element["decoration"]);
                }).toList())
          ],
        ),
      )),
      const MusicList()
    ]));
  }
}
