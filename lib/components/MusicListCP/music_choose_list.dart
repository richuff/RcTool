import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/widget/slide_fade_in.dart';
import 'package:rctool/widget/song_actions_sheet.dart';
import 'package:rctool/widget/song_row.dart';

/// @ClassName MusicChooseList
/// @Description 当前播放队列：队列概览卡（数量 / 播放全部 / 清空）+ 紧凑图标式播放模式
///             + 带序号的歌曲行。播放模式由原先的整行文字按钮收成图标，减少占位。
/// @Author richuff
/// @Version 2.0
class MusicChooseList extends StatelessWidget {
  final MusicController musicController = Get.find<MusicController>();

  MusicChooseList({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GetBuilder<MusicController>(
      builder: (controller) {
        final list = controller.musiclist.whereType<Music>().toList();
        final header = _queueCard(context, controller, list);

        if (list.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 18),
            children: [header, _emptyState(scheme)],
          );
        }

        // 长按任意歌曲即可拖动排序；播放索引会跟随当前歌曲移动
        return ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 18),
          header: header,
          buildDefaultDragHandles: false,
          itemCount: list.length,
          onReorder: controller.reorderQueue,
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final t = Curves.easeOut.transform(animation.value);
                return Material(
                  color: Colors.transparent,
                  elevation: 8 * t,
                  shadowColor: scheme.shadow.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  child: child,
                );
              },
            );
          },
          itemBuilder: (context, index) {
            final music = list[index];
            return ReorderableDelayedDragStartListener(
              key: ValueKey('queue-${music.url}-$index'),
              index: index,
              child: SongRow(
                music: music,
                index: index,
                playing: controller.isPlayingMusic(music),
                loading: controller.loadingUrl.value == music.url &&
                    controller.loadingUrl.value.isNotEmpty,
                onPlayToggle: () => controller.playOrPauseMusic(music),
                onMore: () => showSongActions(
                  context,
                  music,
                  removeLabel: '从播放队列移除'.tr,
                  onRemove: () => _removeWithUndo(controller, music),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 移除后给出「撤销」入口，避免误删还要回去重新找歌
  Future<void> _removeWithUndo(MusicController controller, Music music) async {
    final index = controller.musiclist.indexOf(music);
    if (index < 0) return;
    final removed = controller.removeAt(index);
    if (removed == null) return;
    Get.snackbar(
      '已从队列移除'.tr,
      removed.songName,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      mainButton: TextButton(
        onPressed: () => controller.insertAt(index, removed),
        child: Text('撤销'.tr),
      ),
    );
  }

  /// 队列概览卡：与设置页同源的圆角卡片风格
  Widget _queueCard(
    BuildContext context,
    MusicController controller,
    List<Music> list,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final count = list.length;
    final current =
        count == 0 ? 0 : (controller.position.value + 1).clamp(1, count);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withOpacity(0.16)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primaryContainer,
                      scheme.secondaryContainer,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.queue_music_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '播放队列'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count == 0
                          ? '队列里还没有歌曲'.tr
                          : '共 @count 首 · 正在播放第 @index 首'.trParams(
                              {'count': '$count', 'index': '$current'}),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 0)
                IconButton(
                  tooltip: '清空队列'.tr,
                  onPressed: () => _confirmClear(context, controller),
                  icon: Icon(
                    Icons.delete_sweep_outlined,
                    size: 21,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (count > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.drag_indicator_rounded,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '长按歌曲可拖动排序'.tr,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: FilledButton.icon(
                    onPressed: count == 0
                        ? null
                        : () => controller.playMusicList(list, startIndex: 0),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: Text(
                      '播放全部'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _modeSwitch(context, controller),
            ],
          ),
        ],
      ),
    );
  }

  /// 紧凑图标式播放模式：只保留图标，高度压到 38
  Widget _modeSwitch(BuildContext context, MusicController controller) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeIcon(
            context,
            controller,
            mode: PlayMode.loop,
            icon: Icons.repeat_rounded,
            label: '列表循环'.tr,
          ),
          _modeIcon(
            context,
            controller,
            mode: PlayMode.single,
            icon: Icons.repeat_one_rounded,
            label: '单曲循环'.tr,
          ),
          _modeIcon(
            context,
            controller,
            mode: PlayMode.random,
            icon: Icons.shuffle_rounded,
            label: '随机播放'.tr,
          ),
        ],
      ),
    );
  }

  Widget _modeIcon(
    BuildContext context,
    MusicController controller, {
    required PlayMode mode,
    required IconData icon,
    required String label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = controller.playMode.value == mode;
    return Tooltip(
      message: label,
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () => controller.changePlayMode(mode),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              icon,
              size: 17,
              color: selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withOpacity(0.55),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.queue_music_rounded,
                size: 30,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '播放队列为空，去每日推荐或歌单里挑几首吧'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    MusicController controller,
  ) async {
    final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: Text('清空播放队列'.tr),
            content: Text('将停止播放并移除队列中的歌曲，曲库和歌单不会受影响。'.tr),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('取消'.tr),
              ),
              FilledButton(
                onPressed: () => Get.back(result: true),
                child: Text('清空'.tr),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await controller.clearQueue();
  }
}
