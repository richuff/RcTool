import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/repository/SqlLiteConn/music_conn.dart';
import 'package:rctool/utils/comm_util.dart';

import '../../controller/is_dark_controller.dart';
import '../../controller/music_controller.dart';
import '../../repository/entity/musicEntity/MusicList.dart';
import '../../utils/notification_helper.dart';

class EverydayList extends StatefulWidget {
  const EverydayList({super.key});

  @override
  State<EverydayList> createState() => _EverydayList();
}

class _EverydayList extends State<EverydayList> {
  MusicController musicController = Get.put(MusicController());
  IsDarkController isDarkController = Get.put(IsDarkController());
  final NotificationHelper notificationHelper = NotificationHelper();

  bool inDark = false;

  @override
  void initState() {
    super.initState();
    isDarkController.addListener(() {
      setState(() {
        inDark = isDarkController.isDark.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(5, 5, 0, 5),
              alignment: Alignment.centerLeft,
              child: Text(
                "每日推荐".tr,
                style: const TextStyle(
                  fontSize: 30,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(5, 5, 0, 12),
              alignment: Alignment.centerLeft,
              child: Text(
                "Hi~ 为你准备了以下歌曲，请开始你的音乐之旅吧!".tr,
                style: TextStyle(
                    fontSize: 16,
                    color: inDark
                        ? const Color.fromARGB(140, 255, 255, 255)
                        : const Color.fromARGB(140, 0, 0, 0)),
                textAlign: TextAlign.left,
              ),
            ),
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  Flexible(
                    flex: 2,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(8, 5, 2, 4),
                      decoration: const BoxDecoration(boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 2.0),
                      ]),
                      child: Stack(
                        children: [
                          Positioned(
                              left: 37,
                              top: -8,
                              child: IconButton(
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.play_arrow_sharp,
                                    size: 45,
                                  ))),
                          const Positioned(
                              left: 90,
                              top: 11,
                              child: Text(
                                "播放全部",
                                style: TextStyle(fontSize: 20),
                              ))
                        ],
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(5, 5, 2, 4),
                      decoration: const BoxDecoration(boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 2.0),
                      ]),
                      child: Stack(
                        children: [
                          Positioned(
                              left: 18,
                              top: -4,
                              child: IconButton(
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.access_time_outlined,
                                    size: 40,
                                  )))
                        ],
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(5, 5, 6, 4),
                      decoration: const BoxDecoration(boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 2.0),
                      ]),
                      child: Stack(
                        children: [
                          Positioned(
                              left: 18,
                              top: -4,
                              child: IconButton(
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.favorite_border,
                                    size: 40,
                                  )))
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: allmusiclist.map((element) {
                  return Stack(
                    children: [
                      const SizedBox(
                        height: 80,
                      ),
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
                              image: DecorationImage(
                                  image: NetworkImage(element['imageUrl']!),
                                  fit: BoxFit.cover),
                              color: Colors.pink[100],
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                            ),
                          )),
                      Positioned(
                        left: 90,
                        bottom: 30,
                        child: Text(
                            "${element['songName']}  -----  ${element['decoration']}"),
                      ),
                      Positioned(
                          right: 10,
                          bottom: 18,
                          child: IconButton(
                              onPressed: () async {
                                int? insertId = await MusicConn.queryByNameAndInsertMusic(
                                    element['url']!,
                                    element['imageUrl']!,
                                    element['songName']!,
                                    element['decoration']!);
                                if (insertId == null) {
                                  return;
                                }
                                musicController.inc(
                                    insertId,
                                    element['url']!,
                                    element['imageUrl']!,
                                    element['songName']!,
                                    element['decoration']!);
                                notificationHelper.showNewMusicNotification(
                                    title: "当前正在播放".tr,
                                    body:
                                    "${element['songName']}  -----  ${element['decoration']}");
                                Get.back();
                              },
                              icon: musicController.isplay.value && musicController.getPlaySongName() == element['songName'] ? const Icon(
                                Icons.pause,
                                color: Colors.white,
                              ) :const Icon(
                                Icons.play_arrow_sharp,
                                color: Colors.white,
                              ))),
                    ],
                  );
                }).toList())
          ],
        ));
  }

  @Deprecated("不使用controller插入")
  void incMusicOld(Map<String, String> element) {
    musicController.incOld(
        element['url']!,
        element['imageUrl']!,
        element['songName']!,
        element['decoration']!,
        CommUtil.parseBool(element['isFavorite']));
    notificationHelper.showNewMusicNotification(
        title: "当前正在播放".tr,
        body:
            "${element['songName']}  -----  ${element['decoration']}");
    MusicConn.queryByUrlAndInsert(
        element['url']!,
        element['imageUrl']!,
        element['songName']!,
        element['decoration']!,
        CommUtil.parseBool(element['isFavorite']));
    Get.back();
  }
}
