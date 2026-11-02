import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../feature/theme/type_value.dart';

/// @ClassName LocaleController
/// @Description 语言单一来源。
///
/// 之前语言只写进 `Get.locale` + `Get.updateLocale()`：`Get.locale` 是个普通字段，
/// 赋值本身不会通知任何 widget，只能依赖 `performReassemble()` 全树重刷，
/// 弹层、已缓存的页面偶尔会漏刷，看起来就像「切了语言但还有文案没变」。
/// 这里把当前语言放进 Rx，`MyApp` 用 Obx 监听并直接传给 GetMaterialApp，
/// 切换时 MaterialApp 本身重建，整棵子树（含路由与弹层）必然跟着刷新。
/// @Author richuff
/// @Version 1.0
class LocaleController extends GetxController {
  static const Locale defaultLocale = Locale('zh', 'CN');

  /// 支持的三个语言，顺序即设置页展示顺序
  static const List<Locale> supported = [
    Locale('zh', 'CN'),
    Locale('en', 'US'),
    Locale('ja', 'JP'),
  ];

  final Rx<Locale> locale = defaultLocale.obs;

  /// 从本地配置恢复上次选择的语言（main 里 await 一次，避免首帧闪一下中文）
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(languageCodeKey);
    if (code == null) return;
    final country = prefs.getString(countryCodeKey) ?? '';
    final target = Locale(code, country);
    locale.value = target;
    Get.locale = target;
  }

  Future<void> change(Locale value) async {
    if (locale.value == value) return;
    // 先改 Get.locale：tr 取值时读的就是它，改完再通知界面重建
    Get.locale = value;
    locale.value = value;
    update();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(languageCodeKey, value.languageCode);
    await prefs.setString(countryCodeKey, value.countryCode ?? '');
  }
}
