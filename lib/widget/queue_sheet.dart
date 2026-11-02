import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/repository/entity/Music.dart';

/// @ClassName QueueSheet
/// @Description 当前播放歌单面板：从播放页底部直接弹出，不再跳转到独立页面。
///              点任意一行立即切歌，右侧按钮移出队列，列表随队列变化实时刷新。
/// @Author richuff
/// @Version 1.0
Future<void> showQueueSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _QueueSheet(),
  );
}

class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = MediaQuery.of(context).size.height * 0.66;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: GetBuilder<MusicController>(
        builder: (controller) {
          final list = controller.musiclist.whereType<Music>().toList();
          final currentIndex = controller.position.value;

          return Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outline.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 10, 4),
                child: Row(
                  children: [
                    Icon(Icons.queue_music_rounded,
                        size: 19, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '当前歌单'.tr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${list.length}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '收起'.tr,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close_rounded,
                          size: 20, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? _empty(scheme)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(10, 2, 10, 16),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final music = list[index];
                          final playing = index == currentIndex;
                          return _row(
                            context,
                            scheme,
                            controller,
                            music,
                            index,
                            playing,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(
    BuildContext context,
    ColorScheme scheme,
    MusicController controller,
    Music music,
    int index,
    bool playing,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: playing
            ? scheme.primaryContainer.withOpacity(0.55)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // 点歌直接切过去，然后收起面板回到播放页
            controller.playMusicList(controller.musiclist.whereType<Music>().toList(),
                startIndex: index);
            Get.back();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: playing
                      ? Icon(Icons.graphic_eq_rounded,
                          size: 16, color: scheme.primary)
                      : Text(
                          '${index + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: music.imageUrl.isNotEmpty
                        ? Image.network(
                            music.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _coverFallback(scheme),
                          )
                        : _coverFallback(scheme),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        music.songName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: playing ? scheme.primary : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        music.decoration.trim().isEmpty
                            ? '未知歌手'.tr
                            : music.decoration,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '从队列移除'.tr,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => controller.removeAt(index),
                  icon: Icon(Icons.remove_circle_outline_rounded,
                      size: 19, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverFallback(ColorScheme scheme) {
    return Container(
      color: scheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(Icons.music_note_rounded,
          size: 18, color: scheme.onPrimaryContainer),
    );
  }

  Widget _empty(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.queue_music_rounded,
              size: 40, color: scheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 10),
          Text(
            '队列还是空的'.tr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
