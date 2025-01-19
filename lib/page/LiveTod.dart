import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/widget/SearchWidget.dart';

class LiveTod extends StatefulWidget {
  const LiveTod({super.key});

  @override
  State<LiveTod> createState() => _LiveTod();
}

class _LiveTod extends State<LiveTod> {
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
                            '工具箱'.tr ,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ],
                    )
                ),
              ),
              ListTile(
                leading: const Icon(Icons.music_note),
                title: Text('听音乐'.tr),
                onTap: () {
                  scaffoldKey.currentState?.closeDrawer();
                  Get.toNamed("/music");
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
            actions: [
              SearchWidget()
            ]),
        body: Container(
            decoration:const BoxDecoration(
              image: DecorationImage(
                  opacity: 0.1,
                  image: NetworkImage("https://p0.meituan.net/csc/ac442b7297cabb92da0ad4f114b22660667771.jpg",),
                  fit:BoxFit.cover
              ),
            ),
            child: ListView(
              children:[
                Text(
                  "还在开发中",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.pink[400],
                    fontSize: 25,
                  ),
                ),
              ],
            )
        ));
  }
}
