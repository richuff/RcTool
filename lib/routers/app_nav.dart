import 'package:get/get.dart';

import 'route_path.dart';

/// @ClassName AppNav
/// @Description 顶层页面导航。
///
/// 首页 / 曲库 / 榜单 / 歌单 / 最近播放 / 设置子页这些「平级」页面之间是互斥关系，
/// 不该层层压栈：之前从侧边栏每点一次都会 `Get.toNamed` 压一层新页面，旧页面连同
/// 背景大图、列表状态全部留在内存里，开得越多越卡，最后被系统判定内存超限直接杀掉。
///
/// 这里统一改成「回到栈底首页，再压入目标页」，页面栈深度恒定为 2（首页 + 当前页）。
/// 详情页（歌单详情、播放页、搜索）仍然用普通 push，返回时才回到上一层。
/// @Author richuff
/// @Version 1.0
class AppNav {
  AppNav._();

  /// 切到顶层页面：先清掉首页之上的所有页面（含设置弹窗），再压入目标页
  static Future<void> goTopLevel(String route) async {
    if (Get.currentRoute == route) {
      // 已经在目标页：只把压在它上面的弹窗 / 子页收掉
      Get.until((r) => r.isFirst || r.settings.name == route);
      return;
    }
    if (route == RoutePath.HOME) {
      Get.until((r) => r.isFirst);
      return;
    }
    await Get.offNamedUntil(route, (r) => r.isFirst);
  }
}
