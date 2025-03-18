import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/routers/RoutePath.dart';

import '../controller/MusicController.dart';
import '../utils/NotificationHelper.dart';

class MusicList extends StatefulWidget {
  const MusicList({super.key});

  @override
  State<MusicList> createState() => _MusicList();
}

class _MusicList extends State<MusicList> {
  MusicController musicController = Get.put(MusicController());

  double _sliderValue = 0.0;
  String title = "您还未选择播放的歌曲";
  String decoration = "未知歌手";
  bool isplay = false;
  int _mlength = 0;
  @override
  void initState() {
    setState(() {
      title = musicController.musiclist.length > musicController.position.value
          ? musicController.musiclist[musicController.position.value].songName
          : title;
      _mlength = musicController.musiclist.length;
      decoration = musicController.musiclist.length > musicController.position.value
          ? musicController.musiclist[musicController.position.value].decoration
          : decoration;
    });
    super.initState();
    musicController.addListener(() {
      setState(() {
        title = musicController.musiclist.length >
                musicController.position.value
            ? musicController.musiclist[musicController.position.value].songName
            : title;
        isplay = musicController.isplay.value;
        _mlength = musicController.musiclist.length;
        decoration = musicController.musiclist.length > musicController.position.value
            ? musicController.musiclist[musicController.position.value].decoration
            : decoration;
      });
    });

    musicController.player.onPositionChanged.listen((Duration position) {
      if (musicController.totalDuration != null) {
        double proportion = position.inSeconds / musicController.totalDuration!.inSeconds;
        double sliderValue = proportion * 100; // 转换为1到100的范围
        setState(() {
          _sliderValue = sliderValue;
        });
      }
    });
  }

  final NotificationHelper notificationHelper = NotificationHelper();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(8, 20, 0, 12),
          width: double.infinity,
          height: 50,
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
          left: 100,
          bottom: 32,
          child: Text(title.tr),
        ),
        Positioned(
            right: 95,
            bottom: 20,
            child: IconButton(
                onPressed: () => {musicController.skipPrevious()},
                icon: const Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                ))),
        Positioned(
          left: 70,
          bottom: -3,
          child: Container(
            width: 300,
            child: Slider(
              min: 0.0,
              max: 100.0,
              divisions: 100, // 刻度数量
              value: _sliderValue, // 滑动条当前值
              onChanged: (value) {
                setState(() {
                  _sliderValue = value; // 更新状态变量
                });
                musicController.setPosition(_sliderValue);
              },
            ),
          )
        ),
        Positioned(
            right: 35,
            bottom: 20,
            child: IconButton(
                onPressed: () => {musicController.skipNext()},
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                ))),
        Positioned(
            right: 65,
            bottom: 20,
            child: IconButton(
                onPressed: () => {
                  musicController.playLocal(),
                  notificationHelper.showNewMusicNotification(title: "当前正在播放".tr, body:  "$title  -----  $decoration")
                },
                icon: Icon(
                  isplay ? Icons.pause : Icons.play_arrow_sharp,
                  color: Colors.white,
                ))),
        Positioned(
            right: 2,
            bottom: 20,
            child: IconButton(
                onPressed: () => {
                      setState(() {
                        Get.toNamed(RoutePath.MUSICCHOOSE);
                      })
                    },
                icon: const Icon(
                  Icons.queue_music_sharp,
                  color: Colors.white,
                ))),
        Positioned(
            right: 6,
            bottom: 42,
            child: Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.all(Radius.circular(50))
          ),
              child: Center(
                child: Text(_mlength <= 99 ? "$_mlength" : "99+", style: const TextStyle(fontSize: 10), textAlign: TextAlign.center,),
              ),
        ))
      ],
    );
  }
}
