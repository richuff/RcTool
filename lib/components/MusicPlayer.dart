import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MusicPlayer extends StatefulWidget{

  const MusicPlayer({super.key});

  @override
  State<MusicPlayer> createState() => _MusicCard();
}

class _MusicCard extends State<MusicPlayer>{

  @override
  Widget build(BuildContext context) {

    return Center(
      child: Container(color: Colors.red,),
    );
  }
}