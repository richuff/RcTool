import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/repository/SqlLiteConn/music_conn.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/widget/song_row.dart';

class MusicChooseList extends StatelessWidget {
  final MusicController musicController = Get.put(MusicController());

  MusicChooseList({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GetBuilder<MusicController>(
            builder: (controller) => Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
              child: Row(
                children: [
                  _playModeButton(
                    context,
                    controller: controller,
                    mode: PlayMode.loop,
                    icon: Icons.repeat,
                    label: "循环",
                  ),
                  const SizedBox(width: 8),
                  _playModeButton(
                    context,
                    controller: controller,
                    mode: PlayMode.single,
                    icon: Icons.repeat_one,
                    label: "单曲",
                  ),
                  const SizedBox(width: 8),
                  _playModeButton(
                    context,
                    controller: controller,
                    mode: PlayMode.random,
                    icon: Icons.shuffle,
                    label: "随机",
                  ),
                ],
              ),
            ),
          ),
          GetBuilder<MusicController>(
            builder: (controller) {
              final list = controller.musiclist.whereType<Music>().toList();
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      "播放队列为空",
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: list.map((element) {
                  final playing = controller.isPlayingMusic(element);
                  return SongRow(
                    music: element,
                    playing: playing,
                    onPlayToggle: () => musicController.playOrPauseMusic(element),
                    onRemove: () {
                      musicController.dec(element);
                      MusicConn.deleteByUrl(element.url);
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _playModeButton(
    BuildContext context, {
    required MusicController controller,
    required PlayMode mode,
    required IconData icon,
    required String label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = controller.playMode.value == mode;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => controller.changePlayMode(mode),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: selected ? scheme.secondary : scheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? scheme.secondary : scheme.outline.withOpacity(0.35),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? scheme.onSecondary : scheme.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? scheme.onSecondary : scheme.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
