import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// @ClassName IsDarkController
/// @Description 全局亮/暗模式控制器,驱动 GetMaterialApp 的 themeMode。
/// @Author richuff
/// @Version 1.1
class IsDarkController extends GetxController {
  var isDark = false.obs;

  /// 供 GetMaterialApp.themeMode 取用
  ThemeMode get themeMode => isDark.value ? ThemeMode.dark : ThemeMode.light;

  updateIsDark(bool value) {
    isDark.value = value;
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    update();
  }
}
