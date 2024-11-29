import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

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
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.pink[400],
                ),
                child:const Text(
                  '工具箱',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                title: const Text('听音乐'),
                onTap: () {
                  scaffoldKey.currentState?.closeDrawer();
                  Get.toNamed("/music");
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
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 15, 0),
                child: IconButton(
                    hoverColor: Colors.pink[100],
                    focusColor: Colors.pink[100],
                    highlightColor: Colors.pink[200],
                    onPressed: () {
                      print("搜索栏");
                    },
                    icon: const Icon(Icons.search, size: 26)),
              )
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
                "关于作者or作者的话",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.pink[400],
                  fontSize: 30,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ListTile(
                title: const Text("关于作者", style: TextStyle(color: Colors.black,fontSize: 18)),
                subtitle: const Text(
                  "我是一个什么都学的建模动画编程爱好者,会给大家分享前端后端以及android开发unity开发的笔记和心得体会，大家可以去的我的博客逛逛:richuff.top",
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
                title: const Text(
                  "作者的话",
                  style: TextStyle(color: Colors.black,fontSize: 18),
                ),
                subtitle: const Text(
                  "这是我用flutter构建的第一个作品,主要用于听音乐和live2d的展示和图片的展示",
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
