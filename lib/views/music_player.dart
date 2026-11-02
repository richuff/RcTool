import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/constant/playlist_const.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/repository/SqlLiteConn/music_conn.dart';
import 'package:rctool/routers/route_path.dart';

import '../components/ms_card.dart';
import '../components/music_list.dart';
import '../repository/entity/Music.dart';

/// @ClassName MusicPlayer
/// @Description 听音乐页：标题 + 四个统一的快捷入口 + 正在播放卡片横向列表 + 底部紧凑播放条。
/// @Author richuff
/// @Version 2.0
class MusicPlayer extends StatefulWidget {
  const MusicPlayer({super.key});

  @override
  State<MusicPlayer> createState() => _MusicCard();
}

class _MusicCard extends State<MusicPlayer> {
  MusicController musicController = Get.find<MusicController>();

  List<Music> msList = [];
  bool isEmpty = true;

  updateList() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMusicList();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMusicList();
    });
    musicController.addListener(updateList);
  }

  @override
  void dispose() {
    musicController.removeListener(updateList);
    super.dispose();
  }

  Future<void> _loadMusicList() async {
    if (!mounted) return;
    msList = await MusicConn.queryAll();
    if (!mounted) return;
    setState(() {
      isEmpty = msList.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(context),
        _quickEntries(context),
        const SizedBox(height: 10),
        Expanded(child: _carousel(context)),
        const MusicList(),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = musicController.musiclist.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [scheme.primary, scheme.secondary],
            ).createShader(bounds),
            child: Text(
              "听音乐".tr,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '队列 @count 首'.trParams({'count': '$count'}),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 四个等宽、同风格的快捷入口，替代原先两套不一致的工具栏卡片
  Widget _quickEntries(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = <_QuickEntryData>[
      _QuickEntryData(
        icon: Icons.auto_awesome_rounded,
        label: '每日推荐'.tr,
        color: scheme.primary,
        onTap: () => Get.toNamed(RoutePath.RECOMMEND),
      ),
      _QuickEntryData(
        icon: Icons.favorite_rounded,
        label: '我的喜欢'.tr,
        color: scheme.error,
        onTap: () => Get.toNamed(
          RoutePath.PLAYLIST,
          arguments: favoritePlaylist(),
        ),
      ),
      _QuickEntryData(
        icon: Icons.emoji_events_rounded,
        label: '排行榜'.tr,
        color: scheme.tertiary,
        onTap: () => Get.toNamed(RoutePath.RANKING),
      ),
      _QuickEntryData(
        icon: Icons.queue_music_rounded,
        label: '歌单'.tr,
        color: scheme.secondary,
        onTap: () => Get.toNamed(RoutePath.ALBUM),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _QuickEntry(data: entries[i])),
          ],
        ],
      ),
    );
  }

  Widget _carousel(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: false,
        dragDevices: {
          // 必须设置此事件，不然无法滚动
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 卡片尺寸跟随可用空间，小屏也不会溢出
          final cardHeight = (constraints.maxHeight - 4).clamp(200.0, 520.0);
          final cardWidth = (constraints.maxWidth * 0.74).clamp(210.0, 320.0);
          final cards = isEmpty
              ? <Widget>[
                  MSCard(
                    null,
                    "",
                    "",
                    "您还未选择播放的歌曲".tr,
                    "",
                    width: cardWidth,
                    height: cardHeight,
                  )
                ]
              : msList
                  .map(
                    (element) => MSCard(
                      element.id,
                      element.url,
                      element.imageUrl,
                      element.songName,
                      element.decoration,
                      width: cardWidth,
                      height: cardHeight,
                    ),
                  )
                  .toList();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 12),
                ...cards,
                const SizedBox(width: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickEntryData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickEntryData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickEntry extends StatelessWidget {
  final _QuickEntryData data;

  const _QuickEntry({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 62,
      child: Material(
        color: scheme.surface.withOpacity(0.94),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: data.onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outline.withOpacity(0.18)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(data.icon, size: 21, color: data.color),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
