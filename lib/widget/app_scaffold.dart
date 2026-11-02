import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/feature/design/icon_button_no_ripple.dart';
import 'package:rctool/routers/route_path.dart';
import 'package:rctool/controller/wallpaper_controller.dart';
import 'package:rctool/widget/BackGround/back_ground_enum.dart';
import 'package:rctool/widget/main_drawer.dart';
import 'package:rctool/widget/now_playing_bar.dart';
import 'package:rctool/widget/search_widget.dart';

/// @ClassName AppScaffold
/// @Description 统一页面外壳：封装 Scaffold + Drawer + AppBar(菜单按钮 + 全局设置入口)
///             + 背景装饰，消除各页面重复的脚手架代码。
/// @Author richuff
/// @Version 2.0
class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final BackGroundEnum background;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;

  /// 是否在页面底部挂迷你播放条（队列为空时播放条自己消失）
  final bool nowPlaying;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.background = BackGroundEnum.musicBackGround,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
    this.nowPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      key: scaffoldKey,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawerScrimColor: Colors.transparent,
      drawer: MainDrawer(() => scaffoldKey.currentState?.closeDrawer()),
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 6, top: 6),
            child: IconButtonNoRipple(
              hoverColor: scheme.primaryContainer,
              focusColor: scheme.primaryContainer,
              highlightColor: scheme.secondaryContainer,
              tooltip: '菜单'.tr,
              alignment: Alignment.bottomCenter,
              icon: Icon(Icons.menu, size: 26, color: scheme.onSurface),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        title: title == null
            ? null
            : Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
        centerTitle: false,
        actions: [
          // 曲库搜索入口（歌名 / 歌手）
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: IconButtonNoRipple(
              hoverColor: scheme.primaryContainer,
              focusColor: scheme.primaryContainer,
              highlightColor: scheme.secondaryContainer,
              tooltip: '搜索'.tr,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              onPressed: () => Get.toNamed(RoutePath.SEARCH),
              icon:
                  Icon(Icons.search_rounded, size: 22, color: scheme.onSurface),
            ),
          ),
          const SearchWidget(),
          ...?actions,
          const SizedBox(width: 6),
        ],
      ),
      body: SizedBox.expand(
        child: GetBuilder<WallpaperController>(
          builder: (wallpaper) => DecoratedBox(
            // 换壁纸后换 key，让 DecoratedBox 重新解码图片
            key: ValueKey('bg-${background.slot}-${wallpaper.revision}'),
            decoration: background.decoration,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 暗色下给背景图压一层深色蒙层，避免亮图把整页照得发白
                if (Theme.of(context).brightness == Brightness.dark)
                  IgnorePointer(
                    child: ColoredBox(
                      color: scheme.surface.withOpacity(0.62),
                    ),
                  ),
                Column(
                  children: [
                    Expanded(child: body),
                    // 迷你播放条：队列为空时不占位
                    if (nowPlaying) const NowPlayingBar(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
