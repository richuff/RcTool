import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/iconfont/RcIcon.dart';
import 'package:rctool/widget/SearchWidget.dart';

class AboutAuthor extends StatefulWidget {
  const AboutAuthor({super.key});

  @override
  State<AboutAuthor> createState() => _AboutAuthor();
}

class _AboutAuthor extends State<AboutAuthor> {
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
                leading: const Icon(RcIcon.livetod),
                title: Text('live2d'.tr),
                onTap: () {
                  scaffoldKey.currentState?.closeDrawer();
                  Get.toNamed("/livetod");
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
                "${"关于作者".tr} or ${"作者的话".tr}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.pink[400],
                  fontSize: 25,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ListTile(
                title: Text("关于作者".tr, style: TextStyle(color: Colors.black,fontSize: 18)),
                subtitle: Text(
                  "一".tr,
                  style: TextStyle(color: Colors.black,fontSize: 14),
                ),
                leading: ClipOval(
                  child: Image.network(
                    "https://p1.meituan.net/csc/949ad40707d4b4bab7e2ebafbd649aa8211830.jpg",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ListTile(
                title: Text(
                  "作者的话".tr,
                  style: TextStyle(color: Colors.black,fontSize: 18),
                ),
                subtitle: Text(
                  "二".tr,
                  style: TextStyle(color: Colors.black,fontSize: 14),
                ),
                leading: ClipOval(
                  child: Image.network(
                    "https://p1.meituan.net/csc/949ad40707d4b4bab7e2ebafbd649aa8211830.jpg",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            ],
          )
        ));
  }
}
