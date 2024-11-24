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
              'https://m701.music.126.net/20241124135957/31db35f9f2a80baff2239bd656babb2f/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/28481680626/8c3f/dd57/4c1c/84333f57c88a35512dd3ba34a1a1816f.mp3')),
          MSCard(UrlSource(
              'https://m701.music.126.net/20241124135957/31db35f9f2a80baff2239bd656babb2f/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/28481680626/8c3f/dd57/4c1c/84333f57c88a35512dd3ba34a1a1816f.mp3')),
          MSCard(UrlSource(
              'https://m701.music.126.net/20241124135957/31db35f9f2a80baff2239bd656babb2f/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/28481680626/8c3f/dd57/4c1c/84333f57c88a35512dd3ba34a1a1816f.mp3')),
        ]);
  }
}
