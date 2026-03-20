import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/repository/SqlLiteConn/favorite_conn.dart';

import '../controller/music_controller.dart';
import '../utils/notification_helper.dart';

class MSCard extends StatefulWidget {
  final int? id;
  final String url;
  final String image;
  final String decoration;
  final String songName;

  const MSCard(this.id,this.url, this.image, this.songName, this.decoration,
      {super.key});

  @override
  State<MSCard> createState() => _MSCard();
}

class _MSCard extends State<MSCard> {

  final NotificationHelper notificationHelper = NotificationHelper();
  MusicController musicController = Get.put(MusicController());
  bool isFavorite = false;

  @override
  void initState() async {
    super.initState();
    if (widget.id != null){
      isFavorite = await FavoriteConn.queryByMusicAndCheckFavorite(widget.id ?? 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(top: 20,right: 15,left: 15),
        width: 300,
        height: 530,
        decoration: BoxDecoration(
            image: DecorationImage(
                image: NetworkImage(widget.image), fit: BoxFit.cover, opacity: 0.7),
            color: Get.isDarkMode ? const Color.fromRGBO(255, 243, 242, 0.8) : const Color.fromRGBO(200, 190, 185, 0.8),
            borderRadius: const BorderRadius.all(Radius.circular(50.0)),
            boxShadow: const [BoxShadow(color: Colors.pink, blurRadius: 4.0)]
        ),
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
                      color: Colors.white,
                    ),
                    child: IconButton(
                        iconSize: 32,
                        onPressed: (){
                              setState(() {
                                isFavorite = !isFavorite;
                              });
                          if (widget.id != null){
                            FavoriteConn.deleteByMusicId(widget.id ?? 0);
                          }
                    },
                        icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border)),
                  ),
                )),
            Positioned(
              bottom: 30,
              right: 35,
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.white,
                ),
                child: IconButton(
                    iconSize: 35,
                    onPressed: (){
                      if (widget.url != ""){
                        musicController.inc(widget.id,widget.url,widget.image,widget.songName,widget.decoration);
                        notificationHelper.showNewMusicNotification(title: "当前正在播放".tr, body:  "${widget.songName}  -----  ${widget.decoration}");
                      }
                    },
                    icon: const Icon(
                        Icons.play_arrow_sharp )),
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
