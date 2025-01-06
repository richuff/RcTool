import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:rctool/entity/Music.dart';

class MusicController extends GetxController {
  RxList musiclist = [].obs;
  var isplay = false.obs;
  var position = 0.obs;

  final player = AudioPlayer();

  inc(String url,String imageUrl,String songName,String decoration,bool isFavorite) async {
    Music music = Music(url, imageUrl, songName, decoration,isFavorite);
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
    if (musiclist.isNotEmpty){
      if (isplay.isFalse) {
        isplay.value = true;
        update();
        await player.play(UrlSource(musiclist[position.value].url));
      } else {
        isplay.value = false;
        player.pause();
        update();
      }

      player.onPlayerComplete.listen((event) async {
        isplay.value = false;
        position.value = (position.value + 1) % musiclist.length;
        playLocal();
      });
    }
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
    playLocal();
  }

  skipPrevious() async{
    if (musiclist.isNotEmpty) {
      position.value =
          (position.value - 1 + musiclist.length) % musiclist.length;
      isplay.value = false;
      update();

      playLocal();
    }
  }

  skipNext() async{
    if (musiclist.isNotEmpty) {
      position.value = (position.value + 1) % musiclist.length;
      isplay.value = false;
      update();

      playLocal();
    }
  }
}