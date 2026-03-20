import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:rctool/repository/entity/music_old.dart';

import '../repository/entity/Music.dart';
import '../utils/notification_helper.dart';

class MusicController extends GetxController {
  RxList musiclist = [].obs;
  var isplay = false.obs;
  var position = 0.obs;
  final player = AudioPlayer();
  Duration? totalDuration;

  final cacheManager = DefaultCacheManager();
  final NotificationHelper notificationHelper = NotificationHelper();


  @override
  void dispose() {
    super.dispose();
    player.dispose();
  }

  @override
  void onReady() {
    player.onPlayerComplete.listen((event) async {
      isplay.value = false;
      update();

      playNextLocal();
    });
  }

  Future<void> playCachedAudio(String url) async {
    // 获取缓存文件
    var file = await cacheManager.getSingleFile(url);

    // 播放缓存文件
    await player.play(UrlSource(file.path));
  }

  inc(int? id,String url,String imageUrl,String songName,String decoration) async {
    Music music = Music(id,url, imageUrl, songName, decoration);
    for (Music lMusic in musiclist){
      if (music == lMusic){
        playAt(lMusic);
        return;
      }
    }

    musiclist.add(music);
    update();

    player.stop();
    position.value = musiclist.length-1;
    isplay.value = false;
    update();

    playLocal();
  }

  @Deprecated("废弃isFavorite字段")
  incOld(String url,String imageUrl,String songName,String decoration,bool isFavorite) async {
    MusicOld music = MusicOld(url, imageUrl, songName, decoration,isFavorite);
    for (MusicOld lmusic in musiclist){
      if (music == lmusic){
        playAt(lmusic as Music);
        return;
      }
    }

    musiclist.add(music);
    update();

    player.stop();
    position.value = musiclist.length-1;
    isplay.value = false;
    update();

    playLocal();
  }

  dec(Music music){
    musiclist.remove(music);
    if (position.value > 0){
      position.value = position.value - 1;
    }
    update();
  }

  onPause(){
    isplay.value = false;
    player.pause();
    update();
  }

  playLocal() async {
    if (musiclist.isNotEmpty){
      if (isplay.isFalse) {
        isplay.value = true;
        update();
        await playCachedAudio(musiclist[position.value].url);
      } else {
        onPause();
      }
      totalDuration = await player.getDuration();
      player.onDurationChanged.listen((Duration duration) {
        totalDuration = duration;
      });
    }
  }

  playAway() async {
    if (musiclist.isNotEmpty){
      isplay.value = true;
      update();
      await playCachedAudio(musiclist[position.value].url);
      totalDuration = await player.getDuration();
      player.onDurationChanged.listen((Duration duration) {
        totalDuration = duration;
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
        break;
      }
    }
    playLocal();
  }

  skipPrevious() async{
    if (musiclist.isNotEmpty) {
      position.value =
          (position.value - 1 + musiclist.length) % musiclist.length;
      player.stop();
      onPause();
      playLocal();
    }
  }

  skipNext() async{
    if (musiclist.isNotEmpty) {
      position.value = (position.value + 1) % musiclist.length;
      player.stop();
      onPause();
      playLocal();
    }
  }

  changeLike(Music music) {
    for (int i=0;i<musiclist.length;i++){
      if (musiclist[i] == music){
        musiclist[i].isFavorite = false;
        update();
      }
    }
  }

  //设置播放进度条
  void setPosition(double sliderValue) {
    double proportion = (sliderValue - 1) / 99;
    if (totalDuration != null) {
      Duration newPosition = Duration(seconds: (proportion * totalDuration!.inSeconds).round());
      player.seek(newPosition);
    }
  }

  //播放下一首
  void playNextLocal() async {
    if (musiclist.isNotEmpty){
      if (isplay.isFalse && musiclist.length > 1) {
        isplay.value = true;
        await playCachedAudio(musiclist[(position.value + 1) % musiclist.length].url);

        position.value = (position.value + 1) % musiclist.length;
        update();
      } else {
        onPause();
      }

      //通知栏显示要播放的下一首歌
      notificationHelper.showNewMusicNotification(title: "当前正在播放".tr, body: "${musiclist[position.value].songName}  -----  ${musiclist[position.value].decoration}");

      //监视播放进度s
      totalDuration = await player.getDuration();
      player.onDurationChanged.listen((Duration duration) {
        totalDuration = duration;
      });
    }
  }

  upDateFavorite(Music music) {
    for (int i=0;i<musiclist.length;i++){
      if (musiclist[i].url == music.url){
        musiclist[i] = music;
        update();
        break;
      }
    }
  }

  String getPlaySongName(){
    return musiclist[position.value].songName;
  }
}