import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:rctool/routers/index.dart';
import 'package:rctool/widget/SearchWidget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyApp();
}

class _MyApp extends State<MyApp> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'RcTool',
      debugShowCheckedModeBanner: false,
      getPages: routes,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purpleAccent),
        useMaterial3: true,
      ),
      initialRoute: "/",
      home: Scaffold(
          key: scaffoldKey,
          drawer: Drawer(
            width: 250,
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.pink[200],
                  ),
                  child: Container(
                    height: 40.0, // 设置高度
                    alignment: Alignment.center,
                    child: const Text(
                      '主页',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('msc'),
                  onTap: () {
                    scaffoldKey.currentState?.closeDrawer();
                    Get.toNamed("/music");
                  },
                ),
                ListTile(
                  title: const Text('tst'),
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
                      icon: const Icon(Icons.list),
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
          body: Column(
            children: [
              ElevatedButton(
                  onPressed: () => {

                      },
                  child: const Text("s")),
              ElevatedButton(
                  onPressed: () {
                    Get.toNamed("/test");
                  },
                  child: const Text("e"))
            ],
          )),
    );
  }
}
