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
    //AudioCache audioCache = AudioCache();
    //audioCache.load('Winged_Step.mp3');
    return const Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        MSCard(),
        MSCard(),
        MSCard(),
        ]
    );
  }
}
