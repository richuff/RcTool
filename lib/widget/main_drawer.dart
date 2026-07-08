import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/widget/setting_dialog.dart';

import '../iconfont/rc_icon.dart';
import '../routers/route_path.dart';

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
                  _DrawerSectionLabel(text: "导航"),
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
                  _DrawerSectionLabel(text: "音乐库"),
                  _DrawerItem(
                    icon: Icons.favorite,
                    title: '我的喜欢'.tr,
                    route: RoutePath.MUSICLIKE,
                    closeDrawer: closeDrawer,
                    selectedColor: scheme.primaryContainer,
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
                  _DrawerSectionLabel(text: "其他"),
                  _DrawerItem(
                    icon: RcIcon.livetod,
                    title: 'Live2d',
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
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: scheme.surface.withOpacity(0.88),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withOpacity(0.14),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset("image/RcTool.png", fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "RcTool",
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Music & Live2D",
                  style: TextStyle(
                    color: scheme.onPrimaryContainer.withOpacity(0.72),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          onTap: () {
            closeDrawer();
            if (Get.currentRoute != route) {
              Get.toNamed(route);
            }
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
        onTap: () {
          closeDrawer();
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
