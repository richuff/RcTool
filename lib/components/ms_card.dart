import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/repository/entity/Music.dart';

import '../controller/favorite_controller.dart';
import '../controller/music_controller.dart';
import '../utils/notification_helper.dart';

class MSCard extends StatefulWidget {
  final int? id;
  final String url;
  final String image;
  final String decoration;
  final String songName;

  const MSCard(this.id, this.url, this.image, this.songName, this.decoration,
      {super.key});

  @override
  State<MSCard> createState() => _MSCard();
}

class _MSCard extends State<MSCard> {
  final NotificationHelper notificationHelper = NotificationHelper();
  MusicController musicController = Get.put(MusicController());
  FavoriteController favoriteController = Get.put(FavoriteController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      favoriteController.ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
        margin: const EdgeInsets.only(top: 20, right: 15, left: 15),
        width: 300,
        height: 530,
        decoration: BoxDecoration(
            image: DecorationImage(
                image: NetworkImage(widget.image),
                fit: BoxFit.cover,
                opacity: 0.7),
            color: scheme.surface.withOpacity(Get.isDarkMode ? 0.86 : 0.78),
            borderRadius: const BorderRadius.all(Radius.circular(50.0)),
            boxShadow: [
              BoxShadow(color: scheme.primary.withOpacity(0.45), blurRadius: 4.0)
            ]),
        child: Stack(
          children: [
            Positioned(
                top: 20,
                right: 35,
                child: Opacity(
                  opacity: 0.7,
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: scheme.surface,
                    ),
                    child: GetBuilder<FavoriteController>(
                      builder: (controller) {
                        final isFavorite = controller.isFavorite(widget.id);
                        return IconButton(
                            iconSize: 32,
                            onPressed: () async {
                              if (widget.id == null) return;
                              try {
                                await controller.toggle(widget.id);
                              } catch (e) {
                                print("收藏失败：$e");
                                Get.snackbar("收藏失败".tr, "$e",
                                    snackPosition: SnackPosition.BOTTOM);
                              }
                            },
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : null,
                            ));
                      },
                    ),
                  ),
                )),
            Positioned(
              bottom: 30,
              right: 35,
              child: GetBuilder<MusicController>(
                builder: (controller) {
                  final music = Music(widget.id, widget.url, widget.image,
                      widget.songName, widget.decoration);
                  final playing = controller.isPlayingMusic(music);
                  return Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: playing ? scheme.secondary : scheme.surface,
                    ),
                    child: IconButton(
                        iconSize: 35,
                        onPressed: () {
                          if (widget.url != "") {
                            controller.playOrPauseMusic(music);
                            if (!playing) {
                              notificationHelper.showNewMusicNotification(
                                  title: "当前正在播放".tr,
                                  body:
                                      "${widget.songName}  -----  ${widget.decoration}");
                            }
                          }
                        },
                        icon: Icon(
                          playing ? Icons.pause : Icons.play_arrow_sharp,
                          color:
                              playing ? scheme.onSecondary : scheme.onSurface,
                        )),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 50,
              left: 30,
              child: Text(
                widget.songName,
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
            Positioned(
                bottom: 20,
                left: 30,
                child: Text(
                  widget.decoration,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                )),
          ],
        ));
  }
}
