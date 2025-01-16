import 'package:flutter/material.dart';

class Hotlist extends StatefulWidget {
  @override
  State<Hotlist> createState() => _Hotlist();
}

class _Hotlist extends State<Hotlist> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 300,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                    margin: const EdgeInsets.fromLTRB(10, 10,0,0),
                    child: ElevatedButton(
                      onPressed: () {},
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
                  width: 45,
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
                  width: 45,
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
        ));
  }
}
