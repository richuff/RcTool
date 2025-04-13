import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/routers/RoutePath.dart';

class RightToolbar extends StatefulWidget {
  @override
  State<RightToolbar> createState() => _RightToolbar();
}

class _RightToolbar extends State<RightToolbar> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
            flex: 1,
            child: GestureDetector(
              onTap: () {
                Get.toNamed(RoutePath.RANKING);
              },
              child: Container(
                  height: double.infinity,
                  width: 75,
                  margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                  decoration: BoxDecoration(
                      color: Colors.pink[100],
                      borderRadius: const BorderRadius.all(Radius.circular(6))),
                  child: Stack(
                    children: [
                      Positioned(
                          right: 0,
                          bottom: 0,
                          child: Image.asset(
                            "image/Reward.png",
                            width: 52,
                            height: 52,
                          )),
                       Positioned(
                          left: 4,
                          top: 4,
                          child: Text(
                            "排行榜".tr,
                            style: const TextStyle(fontSize: 15, color: Colors.white),
                          )),
                    ],
                  )),
            )),
        Flexible(
            flex: 1,
            child: GestureDetector(
                onTap: () {
                  Get.toNamed(RoutePath.ALBUM);
                },
                child: Container(
                    width: 75,
                    height: double.infinity,
                    margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                    decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius:
                            const BorderRadius.all(Radius.circular(6))),
                    child: Stack(
                      children: [
                        Positioned(
                            right: 0,
                            bottom: 0,
                            child: Image.asset(
                              "image/Expect.png",
                              width: 52,
                              height: 52,
                            )),
                        Positioned(
                            left: 4,
                            top: 4,
                            child: Text(
                              "歌单".tr,
                              style:
                                  const TextStyle(fontSize: 16, color: Colors.white),
                            )),
                      ],
                    ))))
      ],
    );
  }
}

/*
Container(
                    margin: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                    child: IconButton(
                      iconSize: 45,
                      onPressed: () {
                        Get.toNamed(RoutePath.MUSICLIKE);
                      },
                      style: ElevatedButton.styleFrom(
                        fixedSize: const Size(75, 50),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.pink[200], // 文字颜色
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15), // 左上角为圆形
                              bottomRight: Radius.circular(15), // 右下角为圆形
                              topRight: Radius.circular(6),
                              bottomLeft: Radius.circular(6) // 右下角为圆形
                              ),
                        ),
                        elevation: 5, // 按钮的阴影高度
                        padding: const EdgeInsets.symmetric(
                            horizontal: 1, vertical: 1), // 按钮内边距
                        side: BorderSide(
                          color: Colors.pink[200]!, // 按钮边框颜色
                          width: 2, // 边框宽度
                        ),
                      ),
                      icon: const Icon(Icons.recommend),
                    )),

Container(
                    margin: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                    child: IconButton(
                      iconSize: 45,
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        fixedSize: const Size(75, 50),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.pink[200], // 文字颜色
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15), // 左上角为圆形
                              bottomRight: Radius.circular(15), // 右下角为圆形
                              topRight: Radius.circular(6),
                              bottomLeft: Radius.circular(6)),
                        ),
                        elevation: 5, // 按钮的阴影高度

                        padding: const EdgeInsets.symmetric(
                            horizontal: 1, vertical: 1), // 按钮内边距
                        side: BorderSide(
                          color: Colors.pink[200]!, // 按钮边框颜色
                          width: 2, // 边框宽度
                        ),
                      ),
                      icon: const Icon(Icons.hourglass_top),
                    )),*/
