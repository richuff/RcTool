import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/MusicController.dart';

class MusicList extends StatefulWidget {
  const MusicList({super.key});

  @override
  State<MusicList> createState() => _MusicList();
}

class _MusicList extends State<MusicList> {
  MusicController musicController = Get.put(MusicController());

  String title = "您还未选择播放的歌曲";
  bool isplay = false;
  @override
  void initState() {
    setState(() {
      title = musicController.musiclist.length >
          musicController.position.value
          ? musicController.musiclist[musicController.position.value].songName
          : title;
    });
    super.initState();
    musicController.addListener(() {
      setState(() {
        title = musicController.musiclist.length >
                musicController.position.value
            ? musicController.musiclist[musicController.position.value].songName
            : title;
        isplay = musicController.isplay.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(8, 20, 0, 12),
          width: double.infinity,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.pink[200],
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color.fromRGBO(255, 20, 147, 0.4),
                Color.fromRGBO(255, 80, 107, 0.4),
                Color.fromRGBO(255, 105, 180, 0.4)
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(255, 105, 180, 0.4),
                blurRadius: 10.0,
              )
            ],
          ),
        ),
        Positioned(
            left: 8,
            top: 0,
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                image: const DecorationImage(
                    image: NetworkImage(
                        "https://img.meituan.net/csc/d05518606ba7064dd445508e3cf3d4c42860983.png"),
                    fit: BoxFit.cover),
                color: Colors.pink[100],
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
            )),
        Positioned(
          left: 90,
          bottom: 25,
          child: Text(title),
        ),
        Positioned(
            right: 80,
            bottom: 12,
            child: IconButton(
                onPressed: () => {musicController.skipPrevious()},
                icon: const Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                ))),
        Positioned(
            right: 30,
            bottom: 12,
            child: IconButton(
                onPressed: () => {musicController.skipNext()},
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                ))),
        Positioned(
            right: 55,
            bottom: 12,
            child: IconButton(
                onPressed: () => {musicController.playLocal()},
                icon: Icon(
                  isplay?Icons.pause:Icons.play_arrow_sharp,
                  color: Colors.white,
                ))),
        Positioned(
            right: 2,
            bottom: 12,
            child: IconButton(
                onPressed: () => {
                      setState(() {
                        Get.toNamed("/musicchoose");
                      })
                    },
                icon: const Icon(
                  Icons.queue_music_sharp,
                  color: Colors.white,
                ))),
      ],
    );
  }
}
