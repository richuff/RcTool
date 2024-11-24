import 'package:flutter/material.dart';
import '../views/MusicPlayer.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPage();
}

class _MusicPage extends State<MusicPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.pink[50],
            leading: Column(children: [
              const Padding(padding: EdgeInsets.only(top: 8)),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: IconButton(
                  hoverColor: Colors.pink[100],
                  focusColor: Colors.pink[100],
                  highlightColor: Colors.pink[200],
                  alignment: Alignment.bottomCenter,
                  icon: const Icon(Icons.list,size: 26,),
                  color: Colors.black,
                  onPressed: () {
                    print("侧边栏");
                  },
                ),
              ),
            ]),
            actions: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0 , 8 , 15 , 0),
                child: IconButton(
                    hoverColor: Colors.pink[100],
                    focusColor: Colors.pink[100],
                    highlightColor: Colors.pink[200],
                    onPressed: () {
                      print("搜索栏");
                    },
                    icon: const Icon(Icons.search,size: 26)),
              )
            ]),
        body:const Column(
          children: [
            MusicPlayer()
          ],
        )
    );
  }
}