import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../routers/RoutePath.dart';

class Lefttoolbar extends StatefulWidget {
  const Lefttoolbar({super.key});

  @override
  State<Lefttoolbar> createState() => _Lefttoolbar();
}

class _Lefttoolbar extends State<Lefttoolbar> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Get.toNamed(RoutePath.RECOMMEND);
          },
          child: Container(
            width: 150,
            margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
            decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: const BorderRadius.all(Radius.circular(6))),
            child: Stack(
              children: [
                Positioned(
                    right: 0,
                    bottom: 0,
                    child: Image.asset(
                      "image/Mika.gif",
                      width: 100,
                      height: 100,
                    )),
                Positioned(
                    left: 4,
                    top: 8,
                    child: Text(
                      "每日推荐".tr,
                      style: const TextStyle(fontSize: 28, color: Colors.white),
                    )),
                const Positioned(
                    left: 10,
                    top: 41,
                    child: Text(
                      "blue archive",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        GestureDetector(
          onTap: () {
            Get.toNamed(RoutePath.MUSICLIKE);
          },
          child: Container(
            width: 150,
            margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
            decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: const BorderRadius.all(Radius.circular(6))),
            child: Stack(
              children: [
                Positioned(
                    right: 0,
                    bottom: 0,
                    child: Image.asset(
                      "image/ARoNa.png",
                      width: 100,
                      height: 100,
                    )),
                Positioned(
                    left: 4,
                    top: 8,
                    child: Text(
                      "我的喜欢".tr,
                      style: const TextStyle(fontSize: 28, color: Colors.white),
                    )),
                const Positioned(
                    left: 10,
                    top: 41,
                    child: Text(
                      "archive",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    )),
              ],
            ),
          ),
        )
      ],
    );
  }
}

/*SizedBox(
        height: 300,
        child:Column(
          children: [
            Row(
              children: [
                Container(
                    margin: const EdgeInsets.fromLTRB(10, 10,0,0),
                    child: ElevatedButton(
                      onPressed: () {
                        Get.toNamed(RoutePath.RECOMMEND);
                      },
                      style: ElevatedButton.styleFrom(
                        fixedSize: const Size(90, 70),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.pink[200], // 文字颜色
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15), // 左上角为圆形
                            bottomRight: Radius.circular(15), // 右下角为圆形
                          ),
                        ),
                        elevation: 5, // 按钮的阴影高度
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10), // 按钮内边距
                        side: BorderSide(
                          color: Colors.pink[200]!, // 按钮边框颜色
                          width: 2, // 边框宽度
                        ),
                      ),
                      child: const Text("每日推荐"),
                    )),
                const SizedBox(
                  width: 40,
                ),
                Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        fixedSize: const Size(95, 70),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.pink[200], // 文字颜色
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15), // 左上角为圆形
                            bottomRight: Radius.circular(15), // 右下角为圆形
                          ),
                        ),
                        elevation: 5, // 按钮的阴影高度
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15), // 按钮内边距
                        side: BorderSide(
                          color: Colors.pink[200]!, // 按钮边框颜色
                          width: 2, // 边框宽度
                        ),
                      ),
                      child: const Text("top20"),
                    )),
                const SizedBox(
                  width: 35,
                ),
                Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        fixedSize: const Size(95, 70),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.pink[200], // 文字颜色
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15), // 左上角为圆形
                            bottomRight: Radius.circular(15), // 右下角为圆形
                          ),
                        ),
                        elevation: 5, // 按钮的阴影高度
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 5), // 按钮内边距
                        side: BorderSide(
                          color: Colors.pink[200]!, // 按钮边框颜色
                          width: 2, // 边框宽度
                        ),
                      ),
                      child: const Text("他们都在听"),
                    )),
              ],
            ),
          ],
        ));*/
