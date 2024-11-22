import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MusicCard extends StatefulWidget{

  const MusicCard({super.key});

  @override
  State<MusicCard> createState() => _MusicCard();
}

class _MusicCard extends State<MusicCard>{

  @override
  Widget build(BuildContext context) {

    //AudioCache audioCache = AudioCache();
    //audioCache.load('Winged_Step.mp3');
    return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'can you click me!!',
          ),
          Text(
            'test',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      );
  }
}