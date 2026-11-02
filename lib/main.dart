import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rctool/page/home_page.dart';
import 'package:rctool/routers/Index.dart';
import 'package:rctool/utils/my_message.dart';
import 'package:rctool/utils/notification_helper.dart';
import 'package:rctool/utils/PermissionRequest/Index.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controller/favorite_controller.dart';
import 'controller/is_dark_controller.dart';
import 'feature/theme/type_value.dart';
import 'feature/theme/app_theme.dart';

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

class _MyApp extends State<MyApp> {
  final IsDarkController isDarkController =
      Get.put(IsDarkController(), permanent: true);

  /// 收藏状态全局只保留一个实例：此前每个卡片各自 Get.put 会不断替换实例，
  /// 导致 GetBuilder 监听的是已被丢弃的控制器，点收藏后图标不会立即刷新。
  final FavoriteController favoriteController =
      Get.put(FavoriteController(), permanent: true);
  Locale appLocale = const Locale('zh', 'CN');

  @override
  void initState() {
    super.initState();
    /// @brief 读取SharedPreferences所存的配置
    _readData();
    /// @brief 请求需要的权限
    PermissionRequest.requestNotificationPermission();
    /// @brief 让应用默认只能为竖屏
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  /// @brief 保存SharedPreferences数据
  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(playKey, false);
  }

  /// @brief 读取SharedPreferences数据
  Future<void> _readData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(playKey) == null) {
      _saveData();
    }
    final languageCode = prefs.getString(languageCodeKey);
    final countryCode = prefs.getString(countryCodeKey);
    if (languageCode != null && countryCode != null) {
      setState(() {
        appLocale = Locale(languageCode, countryCode);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<IsDarkController>(builder: (controller) {
      return GetMaterialApp(
        title: 'RcTool', //应用名
        debugShowCheckedModeBanner: false, // 测试时显示debug框
        getPages: routes, //设置路由
        theme: AppTheme.light, //亮色主题(主色:淡粉色)
        darkTheme: AppTheme.dark, //暗色主题
        themeMode: controller.themeMode,
        translations: MyMessage(),
        locale: appLocale,
        //指定默认的语言
        fallbackLocale: const Locale('en', 'US'),
        home: const HomePage(),
      );
    });
  }
}
