import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rctool/routers/RoutePath.dart';
import 'package:rctool/routers/Index.dart';
import 'package:rctool/utils/my_message.dart';
import 'package:rctool/utils/notification_helper.dart';
import 'package:rctool/utils/PermissionRequest/Index.dart';
import 'package:rctool/repository/SqlLiteConn/index.dart';
import 'package:rctool/widget/BackGround/back_ground_enum.dart';
import 'package:rctool/widget/main_drawer.dart';
import 'package:rctool/widget/search_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'feature/Theme/TypeValue.dart';
import 'feature/design/IconButtonNoRipple.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  /// @brief 初始化通知(NotificationHelper)
  final notificationHelper = NotificationHelper();
  await notificationHelper.initialize();
  /// @brief 用户入口
  runApp(const MyApp());
}

/// @ClassName MyApp
/// @Description App入口
/// @Author richuff
/// @Date 2024-10-10
/// @Version 1.0

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
    /// @brief 加载sqllite
    SqlLiteConn.initState();
    /// @brief 读取SharedPreferences所存的配置
    _readData();
    /// @brief 请求需要的权限
    PermissionRequest.requestNotificationPermission();
    /// @brief 让应用默认只能为竖屏
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    /// @brief 让应用的状态栏显示未指定颜色
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //     statusBarColor: Color.fromARGB(255,246,209,245),
    //     statusBarIconBrightness: Brightness.dark));
  }


  /// @brief 保存SharedPreferences数据
  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(playKey, true);
  }
  /// @brief 读取SharedPreferences数据
  Future<void> _readData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(playKey) == null) {
      _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        title: 'RcTool',  //应用名
        debugShowCheckedModeBanner: false, // 测试时显示debug框
        getPages: routes,  //设置路由
        theme: ThemeData( //设置主题
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.purpleAccent),
          useMaterial3: true,
        ),
        initialRoute: RoutePath.HOME, //初始路径
        translations: MyMessage(),
        locale: const Locale('zh', 'CN'),
        //指定默认的语言
        fallbackLocale: const Locale('en', 'US'),
        //添加一个回调语言选项
        home: Scaffold(
            key: scaffoldKey,
            drawerScrimColor: Colors.transparent,
            drawer: MainDrawer(() {
              scaffoldKey.currentState?.closeDrawer();
            }),
            appBar: AppBar(
                backgroundColor: Colors.pink[50],
                leading: Builder(builder: (context) {
                  return Column(children: [
                    const Padding(padding: EdgeInsets.only(top: 8)),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: IconButtonNoRipple(
                        hoverColor: Colors.pink[100],
                        focusColor: Colors.pink[100],
                        highlightColor: Colors.pink[200],
                        alignment: Alignment.bottomCenter,
                        icon: const Icon(
                          Icons.menu,
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
                actions: const [SearchWidget()]),
            body: SafeArea(
              child: Container(
                decoration: BackGroundEnum.homeBackGround.decoration,
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
                                Image.asset(
                                  "image/Love.png",
                                  height: 100,
                                  width: 100,
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
