import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:rctool/entity/Music.dart';

class MusicController extends GetxController {
  RxList musiclist = [].obs;
  var isplay = false.obs;
  var position = 0.obs;

  final player = AudioPlayer();

  inc(String url,String imageUrl,String songName,String decoration) async {
    Music music = Music(url, imageUrl, songName, decoration);
    for (Music lmusic in musiclist){
      if (music == lmusic){
        return;
      }
    }
    musiclist.add(music);
    update();
    if (isplay.isFalse){
      position.value = musiclist.length-1;
      update();
      playLocal();
    }
  }
  dec(Music music){
    musiclist.remove(music);
    if (position.value > 0){
      position.value = position.value - 1;
    }
    update();
  }


  playLocal() async {
    if (isplay.isFalse) {
      isplay.value = true;
      await player.play(UrlSource(musiclist[position.value].url));
      update();
    } else {
      isplay.value = false;
      player.pause();
      update();
    }
    player.onPlayerComplete.listen((event) async {
      position.value = position.value + 1;
      isplay.value = false;
      update();

      if (position.value < musiclist.length){
        playLocal();
      }else {
        isplay.value = false;
        position.value = 0;
        update();
      }
    });
  }

  playAt(Music music) async {
    for (int i=0;i<musiclist.length;i++){
      if (musiclist[i] == music){
        if (position.value == i){
          return;
        }
        position.value = i;
        isplay.value = false;
        update();
      }
    }

    if (isplay.isFalse) {
      isplay.value = true;
      await player.play(UrlSource(musiclist[position.value].url));
      update();
    } else {
      isplay.value = false;
      player.pause();
      update();
    }
    player.onPlayerComplete.listen((event) async {
      position.value = position.value + 1;
      isplay.value = false;
      update();

      if (position.value < musiclist.length){
        playLocal();
      }else {
        isplay.value = false;
        position.value = 0;
        update();
      }
    });
  }
}