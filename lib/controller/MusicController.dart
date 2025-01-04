import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:rctool/entity/Music.dart';

class MusicController extends GetxController {
  RxList musiclist = [].obs;
  var isplay = false.obs;
  final player = AudioPlayer();

  inc(String url,String imageUrl,String songName,String decoration) async {
    Music music = Music(url, imageUrl, songName, decoration);
    for (Music lmusic in musiclist){
      if (music == lmusic){
        return;
      }
    }
    update();
    print(musiclist);
    if (isplay.isFalse){
      playLocal(musiclist.length-1);
    }
  }
  dec(Music music){
    musiclist.remove(music);
    update();
  }


  playLocal(int position) async {
    if (isplay.isFalse) {
      isplay.value = true;
      await player.play(UrlSource(musiclist[position].url));
      update();
    } else {
      isplay.value = false;
      player.pause();
      update();
    }
    player.onPlayerComplete.listen((event) async {
      if (position+1 < musiclist.length-1){
        await player.play(UrlSource(musiclist[position+1].url));
      }else {
        isplay.value = false;
        update();
      }
    });
  }
}