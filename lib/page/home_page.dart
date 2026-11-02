import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/constant/app_info.dart';
import 'package:rctool/constant/playlist_const.dart';
import 'package:rctool/routers/route_path.dart';
import 'package:rctool/widget/BackGround/back_ground_enum.dart';
import 'package:rctool/widget/app_scaffold.dart';
import 'package:rctool/widget/now_playing_bar.dart';
import 'package:rctool/widget/slide_fade_in.dart';

/// @ClassName HomePage
/// @Description 首页：渐变欢迎卡 + 快速开始入口 + 音乐库入口，底部常驻迷你播放条。
/// @Author richuff
/// @Version 2.0
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppScaffold(
      background: BackGroundEnum.homeBackGround,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: [
                const SlideFadeIn(child: _WelcomeCard()),
                const SizedBox(height: 20),
                _sectionLabel(context, '快速开始'.tr),
                const SlideFadeIn(
                  delay: Duration(milliseconds: 80),
                  child: Row(
                    children: [
                      Expanded(
                        child: _EntryTile(
                          icon: Icons.music_note_rounded,
                          title: '听音乐',
                          subtitle: '曲库 · 队列 · 收藏',
                          route: RoutePath.MUSIC,
                          primary: true,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _EntryTile(
                          icon: Icons.face_retouching_natural,
                          title: 'Live2D',
                          subtitle: '与 Haru 互动',
                          route: RoutePath.LIVETOD,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _sectionLabel(context, '音乐库'.tr),
                SlideFadeIn(
                  delay: const Duration(milliseconds: 160),
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surface.withOpacity(0.94),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: scheme.outline.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        _MenuRow(
                          icon: Icons.auto_awesome_rounded,
                          title: '每日推荐'.tr,
                          subtitle: '每天为你准备一组歌曲',
                          route: RoutePath.RECOMMEND,
                        ),
                        _divider(scheme),
                        _MenuRow(
                          icon: Icons.emoji_events_rounded,
                          title: '排行榜'.tr,
                          subtitle: '看看哪些歌最热门',
                          route: RoutePath.RANKING,
                        ),
                        _divider(scheme),
                        _MenuRow(
                          icon: Icons.favorite_rounded,
                          title: '我的喜欢'.tr,
                          subtitle: '默认歌单，收藏都汇总在这里',
                          onTap: () => Get.toNamed(
                            RoutePath.PLAYLIST,
                            arguments: favoritePlaylist(),
                          ),
                        ),
                        _divider(scheme),
                        _MenuRow(
                          icon: Icons.queue_music_rounded,
                          title: '歌单'.tr,
                          subtitle: '整理自己的播放列表',
                          route: RoutePath.ALBUM,
                        ),
                        _divider(scheme),
                        _MenuRow(
                          icon: Icons.insights_rounded,
                          title: '播放统计'.tr,
                          subtitle: '最近 7 天与常听榜单',
                          route: RoutePath.STATS,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 有正在播放的歌曲时出现
          const NowPlayingBar(),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme scheme) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 12,
      color: scheme.outline.withOpacity(0.12),
    );
  }
}

/// 渐变欢迎卡
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.secondaryContainer,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -28,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface.withOpacity(0.24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: scheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Image.asset('image/RcTool.png', fit: BoxFit.contain),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '欢迎使用Rctool'.tr,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '你可以听音乐和使用live2d功能'.tr,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: scheme.onPrimaryContainer.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'v${AppInfo.version}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onPrimaryContainer.withOpacity(0.6),
                        ),
                      ),
                    ],
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

/// 快速开始大卡片
class _EntryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final bool primary;

  const _EntryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = primary ? scheme.primary : scheme.secondary;
    final foreground = primary ? scheme.onPrimary : scheme.onSecondary;
    return SizedBox(
      height: 118,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Get.toNamed(route),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  background,
                  Color.alphaBlend(
                    Colors.black.withOpacity(0.18),
                    background,
                  ),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: background.withOpacity(0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 26, color: foreground),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: foreground.withOpacity(0.82),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 音乐库入口行
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? route;
  final VoidCallback? onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.route,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: scheme.outline),
      onTap: onTap ?? () => Get.toNamed(route!),
    );
  }
}
