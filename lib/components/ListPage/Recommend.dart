import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_common/get_reset.dart';
import 'package:get/get_core/src/get_main.dart';

class Recommend extends StatefulWidget {
  @override
  State<Recommend> createState() => _Recommend();
}

class _Recommend extends State<Recommend> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 300,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                    margin: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                    child: IconButton(
                      iconSize: 45,
                      onPressed: () {
                        Get.toNamed("/musiclike");
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
                const SizedBox(
                  width: 45,
                ),
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
                      icon: const Icon(Icons.people),
                    )),
                const SizedBox(
                  width: 45,
                ),
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
                    )),
              ],
            ),
          ],
        ));
  }
}
