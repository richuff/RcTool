import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MusicPlayer extends StatefulWidget {
  const MusicPlayer({super.key});

  @override
  State<MusicPlayer> createState() => _MusicCard();
}

class _MusicCard extends State<MusicPlayer> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
          child: Column(
            children:[
              const Flexible(child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(child: Text("test"),height: 500,),
                    SizedBox(child: Text("test"),height: 500,),
                    SizedBox(child: Text("test"),height: 500,),
                    SizedBox(child: Text("test"),height: 500,),
                    Text("data")
                  ],
                ),
              )
              ),
              Stack(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 50),
                    width: double.infinity,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: const Color.fromARGB(100, 175, 175, 241),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromARGB(100, 147, 147, 216),
                          blurRadius: 10.0,
                        )
                      ],
                    ),
                    child: ListView(
                      children: const [
                        Text("True")
                      ],
                    ),
                  ),
                ],
              ),
          ])
    );
  }
}
