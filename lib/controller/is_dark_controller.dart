import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../feature/theme/type_value.dart';

/// 全局主题控制器，负责主题切换与本地持久化。
class IsDarkController extends GetxController {
  final isDark = false.obs;
  final selectedThemeMode = ThemeMode.light.obs;

  /// 供 GetMaterialApp.themeMode 取用。
  ThemeMode get themeMode => selectedThemeMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(themeModeKey);
    final mode = ThemeMode.values.firstWhere(
      (item) => item.name == savedMode,
      orElse: () => ThemeMode.light,
    );
    selectedThemeMode.value = mode;
    isDark.value = mode == ThemeMode.dark;
    update();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    selectedThemeMode.value = mode;
    isDark.value = mode == ThemeMode.dark;
    Get.changeThemeMode(mode);
    update();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeModeKey, mode.name);
  }

  /// 保留给原有亮/暗切换入口使用。
  Future<void> updateIsDark(bool value) {
    return updateThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }
}
