import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/entity/MusicEntity/EveryDayMusicList.dart';

import '../../controller/MusicController.dart';
import '../../utils/CommUtil.dart';

class EverydayList extends StatefulWidget {
  const EverydayList({super.key});

  @override
  State<EverydayList> createState() => _EverydayList();
}

class _EverydayList extends State<EverydayList> {
  MusicController musicController = Get.put(MusicController());

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: everydaymusiclist.map((element) {
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
                                  image: NetworkImage(element["imageUrl"]!),
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
                            "${element["songName"]}  -----  ${element["decoration"]}"),
                      ),
                      Positioned(
                          right: 10,
                          bottom: 18,
                          child: IconButton(
                              onPressed: () => {
                                    musicController.inc(
                                        element["url"]!,
                                        element["imageUrl"]!,
                                        element["songName"]!,
                                        element["decoration"]!,
                                        CommUtil.parseBool(
                                            element["isFavorite"]))
                                  },
                              icon: const Icon(
                                Icons.play_arrow_sharp,
                                color: Colors.white,
                              ))),
                    ],
                  );
                }).toList())
          ],
        ));
  }
}
