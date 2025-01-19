import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../components/RecommendCP/EveryDayRecommend.dart';
import '../../iconfont/RcIcon.dart';
import '../../widget/SearchWidget.dart';

class Everydaymusic extends StatefulWidget {
  const Everydaymusic({super.key});

  @override
  State<Everydaymusic> createState() => _Everydaymusic();
}

class _Everydaymusic extends State<Everydaymusic> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: Drawer(
        width: 250,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            SizedBox(
              height: 100.0,
              child: DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.pink[200],
                  ),
                  child: Stack(
                    children: [
                      Container(
                        height: 40.0, // 设置高度
                        alignment: Alignment.center,
                        child: Text(
                          '工具箱'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ],
                  )),
            ),
            ListTile(
              leading: const Icon(RcIcon.livetod),
              title: Text('live2d'.tr),
              onTap: () {
                scaffoldKey.currentState?.closeDrawer();
                Get.toNamed("/livetod");
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_box_rounded),
              title: Text('关于作者'.tr),
              onTap: () {
                scaffoldKey.currentState?.closeDrawer();
                Get.toNamed("/about");
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
          backgroundColor: Colors.pink[50],
          leading: Builder(builder: (context) {
            return Column(children: [
              const Padding(padding: EdgeInsets.only(top: 8)),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: IconButton(
                  hoverColor: Colors.pink[100],
                  focusColor: Colors.pink[100],
                  highlightColor: Colors.pink[200],
                  alignment: Alignment.bottomCenter,
                  icon: const Icon(
                    Icons.list,
                    size: 26,
                  ),
                  color: Colors.black,
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            ]);
          }),
          actions: [SearchWidget()]),
      body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
                opacity: 0.1,
                image: NetworkImage(
                    "https://p0.meituan.net/csc/ac442b7297cabb92da0ad4f114b22660667771.jpg"),
                fit: BoxFit.cover),
          ),
          child: Column(children: [
            Flexible(
                child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false, dragDevices: {
                      //必须设置此事件，不然无法滚动
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    }),
                    child: const EverydayList())),
          ])),
    );
  }
}
