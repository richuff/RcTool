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
import 'controller/locale_controller.dart';
import 'controller/music_controller.dart';
import 'controller/offline_controller.dart';
import 'controller/wallpaper_controller.dart';
import 'feature/theme/type_value.dart';
import 'feature/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// @brief 初始化通知(NotificationHelper)
  final notificationHelper = NotificationHelper();
  await notificationHelper.initialize();

  /// @brief 全局控制器：只注册一次，页面统一用 Get.find 取用。
  ///        之前各页面各自 Get.put 会不断替换实例，导致跨页面状态不同步。
  Get.put(MusicController(), permanent: true);
  Get.put(IsDarkController(), permanent: true);
  Get.put(FavoriteController(), permanent: true);
  Get.put(OfflineController(), permanent: true);
  Get.put(WallpaperController(), permanent: true);

  /// @brief 语言：全局单例，切换时让 GetMaterialApp 自己重建，整棵树跟着刷新
  final localeController = Get.put(LocaleController(), permanent: true);
  await localeController.restore();

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
  final IsDarkController isDarkController = Get.find<IsDarkController>();

  /// 收藏状态全局只保留一个实例：此前每个卡片各自 Get.put 会不断替换实例，
  /// 导致 GetBuilder 监听的是已被丢弃的控制器，点收藏后图标不会立即刷新。
  final FavoriteController favoriteController = Get.find<FavoriteController>();
  final LocaleController localeController = Get.find<LocaleController>();

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
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<IsDarkController>(builder: (controller) {
      // Obx 监听语言：切换后 MaterialApp 重建，路由与弹层一起刷新
      return Obx(() => GetMaterialApp(
            title: 'RcTool', //应用名
            debugShowCheckedModeBanner: false, // 测试时显示debug框
            getPages: routes, //设置路由
            theme: AppTheme.light, //亮色主题(主色:淡粉色)
            darkTheme: AppTheme.dark, //暗色主题
            themeMode: controller.themeMode,
            translations: MyMessage(),
            locale: localeController.locale.value,
            // 找不到对应语言时回落到中文
            fallbackLocale: const Locale('zh', 'CN'),
            home: const HomePage(),
          ));
    });
  }
}
