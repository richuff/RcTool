import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/repository/SqlLiteConn/music_conn.dart';

import '../../controller/music_controller.dart';

class MusicChooseList extends StatefulWidget {
  const MusicChooseList({super.key});

  @override
  State<MusicChooseList> createState() => _MusicChooseList();
}

class _MusicChooseList extends State<MusicChooseList> {
  MusicController musicController = Get.put(MusicController());

  List chooseList = [];

  @override
  void initState() {
    super.initState();
    setState(() {
      chooseList = musicController.musiclist;
    });
  }

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
            Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: chooseList.map((element) {
                  return Stack(
                    children: [
                      const SizedBox(height: 80,),
                      Container(
                        margin: const EdgeInsets.fromLTRB(8, 20, 0, 12),
                        width: double.infinity,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: scheme.primaryContainer,
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              scheme.primaryContainer.withOpacity(0.86),
                              scheme.secondaryContainer.withOpacity(0.78),
                              scheme.tertiary.withOpacity(0.24),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.shadow.withOpacity(0.16),
                              blurRadius: 10.0,
                            )
                          ],
                        ),
                      ),
                      Positioned(
                          left: 8,
                          top: 0,
                          child: Container(
                            width: 75,
                            height: 75,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: NetworkImage(element.imageUrl), fit: BoxFit.cover),
                              color: scheme.surfaceVariant,
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                            ),
                          )),
                      Positioned(
                        left: 90,
                        bottom: 30,
                        child: Text("${element.songName}  -----  ${element.decoration}"),
                      ),
                      Positioned(
                          right: 40,
                          bottom: 18,
                          child: GetBuilder<MusicController>(
                            builder: (controller) {
                              final playing =
                                  controller.isPlayingMusic(element);
                              return IconButton(
                                  onPressed: () =>
                                      controller.playOrPauseMusic(element),
                                  icon: Icon(
                                    playing
                                        ? Icons.pause
                                        : Icons.play_arrow_sharp,
                                    color: Colors.white,
                                  ));
                            },
                          )),
                      Positioned(
                          right: 2,
                          bottom: 18,
                          child: IconButton(
                              onPressed: (){
                                musicController.dec(element);
                                MusicConn.deleteByUrl(element.url);
                                setState(() {
                                  chooseList.remove(element);
                                });
                              },
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ))),
                    ],
                  );
                }).toList())
          ],
        ));
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
              color: selected
                  ? scheme.secondary
                  : scheme.outline.withOpacity(0.35),
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
