import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/widget/setting_dialog.dart';

import '../constant/app_info.dart';
import '../iconfont/rc_icon.dart';
import '../routers/app_nav.dart';
import '../routers/route_path.dart';

/// 抽屉收起动画约 246ms。点击抽屉里的入口后要等它收完再切页，
/// 否则「抽屉左滑收起」和「页面切换」两个动画会同时播放，看起来像抖了一下。
const Duration kDrawerCloseDelay = Duration(milliseconds: 240);

/// @ClassName MainDrawer
/// @Description 主菜单窗口
/// @Author richuff
/// @Date 2024-10-12
/// @Version 1.1
class MainDrawer extends StatelessWidget {
  final closeDrawer;

  const MainDrawer(this.closeDrawer, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Drawer(
        width: 282,
        backgroundColor: scheme.surface,
        child: Column(
          children: [
            _DrawerHeader(scheme: scheme),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                children: [
                  _DrawerSectionLabel(text: "导航".tr),
                  _DrawerItem(
                    icon: Icons.home,
                    title: '主页'.tr,
                    route: RoutePath.HOME,
                    closeDrawer: closeDrawer,
                  ),
                  _DrawerItem(
                    icon: Icons.music_note,
                    title: '听音乐'.tr,
                    route: RoutePath.MUSIC,
                    closeDrawer: closeDrawer,
                    selectedColor: scheme.secondaryContainer,
                  ),
                  _DrawerItem(
                    icon: Icons.recommend,
                    title: '每日推荐'.tr,
                    route: RoutePath.RECOMMEND,
                    closeDrawer: closeDrawer,
                  ),
                  _DrawerSectionLabel(text: "音乐库".tr),
                  _DrawerItem(
                    icon: Icons.history,
                    title: '最近播放'.tr,
                    route: RoutePath.HISTORY,
                    closeDrawer: closeDrawer,
                  ),
                  _DrawerItem(
                    icon: Icons.insights,
                    title: '播放统计'.tr,
                    route: RoutePath.STATS,
                    closeDrawer: closeDrawer,
                  ),
                  _DrawerItem(
                    icon: Icons.emoji_events,
                    title: '排行榜'.tr,
                    route: RoutePath.RANKING,
                    closeDrawer: closeDrawer,
                  ),
                  _DrawerItem(
                    icon: Icons.queue_music,
                    title: '歌单'.tr,
                    route: RoutePath.ALBUM,
                    closeDrawer: closeDrawer,
                    selectedColor: scheme.secondaryContainer,
                  ),
                  _DrawerItem(
                    icon: Icons.offline_pin_outlined,
                    title: '离线歌曲'.tr,
                    route: RoutePath.OFFLINE,
                    closeDrawer: closeDrawer,
                  ),
                  _DrawerSectionLabel(text: "其他".tr),
                  _DrawerItem(
                    icon: RcIcon.livetod,
                    title: 'Live2D'.tr,
                    route: RoutePath.LIVETOD,
                    closeDrawer: closeDrawer,
                  ),
                  _DrawerItem(
                    icon: Icons.account_box_rounded,
                    title: '关于作者'.tr,
                    route: RoutePath.ABOUT,
                    closeDrawer: closeDrawer,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: _SettingsButton(closeDrawer: closeDrawer),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final ColorScheme scheme;

  const _DrawerHeader({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            Color.alphaBlend(
              scheme.secondaryContainer.withOpacity(0.72),
              scheme.primaryContainer,
            ),
            scheme.surfaceContainerHighest.withOpacity(0.9),
          ],
          stops: const [0, 0.58, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 装饰光斑，让头部不再是纯色块
          Positioned(
            right: -38,
            top: -46,
            child: _glowBall(118, scheme.surface.withOpacity(0.16)),
          ),
          Positioned(
            right: 34,
            bottom: -54,
            child: _glowBall(96, scheme.primary.withOpacity(0.14)),
          ),
          Row(
            children: [
              // 渐变描边 + 内白的 Logo，比纯色底板更有质感
              Container(
                width: 58,
                height: 58,
                padding: const EdgeInsets.all(1.6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.surface.withOpacity(0.95),
                      scheme.primary.withOpacity(0.55),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(2.4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.4),
                    color: scheme.surface.withOpacity(0.94),
                  ),
                  child:
                      Image.asset("image/RcToolIcon.png", fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 渐变标题
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          scheme.onPrimaryContainer,
                          Color.alphaBlend(
                            scheme.primary.withOpacity(0.85),
                            scheme.onPrimaryContainer,
                          ),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        "RcTool",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surface.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: scheme.surface.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            AppInfo.displayVersion,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color:
                                  scheme.onPrimaryContainer.withOpacity(0.86),
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            "MUSIC · LIVE2D",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.4,
                              color:
                                  scheme.onPrimaryContainer.withOpacity(0.66),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glowBall(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  final String text;

  const _DrawerSectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
      child: Text(
        text,
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final VoidCallback closeDrawer;
  final Color? selectedColor;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.closeDrawer,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentRoute =
        Get.currentRoute.isEmpty ? RoutePath.HOME : Get.currentRoute;
    final selected = currentRoute == route;
    final backgroundColor = selected
        ? selectedColor ?? scheme.primaryContainer
        : Colors.transparent;
    final foregroundColor =
        selected ? scheme.onPrimaryContainer : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            closeDrawer();
            if (Get.currentRoute == route) return;
            await Future.delayed(kDrawerCloseDelay);
            // 顶层页面互斥：换页而不是压栈，否则页面栈会一直变长
            AppNav.goTopLevel(route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon, color: foregroundColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.chevron_right, color: foregroundColor, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final VoidCallback closeDrawer;

  const _SettingsButton({required this.closeDrawer});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          closeDrawer();
          await Future.delayed(kDrawerCloseDelay);
          Get.dialog(const SettingDialog());
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.settings, color: scheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '设置'.tr,
                  style: TextStyle(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.open_in_new,
                size: 18,
                color: scheme.onSecondaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
