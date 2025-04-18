import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rctool/routers/RoutePath.dart';
import 'package:rctool/routers/index.dart';
import 'package:rctool/utils/MyMessage.dart';
import 'package:rctool/utils/NotificationHelper.dart';
import 'package:rctool/utils/PermissionRequest/index.dart';
import 'package:rctool/utils/SqlLiteConn/index.dart';
import 'package:rctool/widget/MainDrawer.dart';
import 'package:rctool/widget/SearchWidget.dart';

import 'iconfont/RcIcon.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationHelper = NotificationHelper();
  await notificationHelper.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyApp();
}

class _MyApp extends State<MyApp> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();

    WidgetsFlutterBinding.ensureInitialized();
    SqlLiteConn.initState();

    PermissionRequest.requestNotificationPermission();
  }

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
        initialRoute: RoutePath.HOME,
        translations: MyMessage(),
        locale: const Locale('zh', 'CN'), //指定默认的语言
        fallbackLocale: const Locale('en', 'US'), //添加一个回调语言选项
        home: Scaffold(
            key: scaffoldKey,
            drawerScrimColor: Colors.transparent,
            drawer: MainDrawer(scaffoldKey),
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
                actions: [SearchWidget()]),
            body: SafeArea(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                      opacity: 0.1,
                      image: NetworkImage(
                          "https://img.meituan.net/csc/d05518606ba7064dd445508e3cf3d4c42860983.png"),
                      fit: BoxFit.cover),
                ),
                child: Center(
                  child: FadeTransition(
                    opacity: _animation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  size: 50,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  '欢迎使用Rctool'.tr,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  '你可以听音乐和使用live2d功能'.tr,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // 按钮1的点击事件
                                Get.toNamed("/music");
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                              ),
                              child: Text('听音乐'.tr),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: () {
                                // 按钮2的点击事件
                                Get.toNamed("/livetod");
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                              ),
                              child: const Text("live2d"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )));
  }
}
