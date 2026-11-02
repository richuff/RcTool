import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:rctool/repository/entity/music_old.dart';

import '../repository/entity/Music.dart';
import '../utils/notification_helper.dart';

enum PlayMode {
  loop,
  single,
  random,
}

class MusicController extends GetxController {
  RxList musiclist = [].obs;
  var isplay = false.obs;
  var position = 0.obs;
  var playMode = PlayMode.loop.obs;
  final player = AudioPlayer();
  Duration? totalDuration;

  final cacheManager = DefaultCacheManager();
  final NotificationHelper notificationHelper = NotificationHelper();
  int _randomSeed = DateTime.now().millisecondsSinceEpoch;


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
      if (_isSameMusic(music, lMusic)){
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

  playMusicList(List<Music> list, {int startIndex = 0}) async {
    if (list.isEmpty) return;
    musiclist.value = list;
    player.stop();
    position.value = startIndex.clamp(0, list.length - 1).toInt();
    isplay.value = false;
    update();
    playLocal();
  }

  addMusicListToQueue(List<Music> list, {bool playFirstAdded = true}) async {
    if (list.isEmpty) return;
    int? firstAddedIndex;

    for (final music in list) {
      final exists = musiclist.any(
        (item) => item is Music && _isSameMusic(music, item),
      );
      if (exists) continue;
      musiclist.add(music);
      firstAddedIndex ??= musiclist.length - 1;
    }

    update();

    if (musiclist.isEmpty) return;
    if (playFirstAdded && firstAddedIndex != null) {
      player.stop();
      position.value = firstAddedIndex;
      isplay.value = false;
      update();
      playLocal();
      return;
    }
    if (isplay.isFalse) {
      playLocal();
    }
  }

  bool _isSameMusic(Music music, Music other) {
    if (music.id != null && other.id != null) {
      return music.id == other.id;
    }
    if (music.url.isNotEmpty && other.url.isNotEmpty) {
      return music.url == other.url;
    }
    return music.songName == other.songName;
  }

  bool isCurrentMusic(Music music) {
    if (musiclist.isEmpty || position.value >= musiclist.length) return false;
    final current = musiclist[position.value];
    if (current is! Music) return false;
    return _isSameMusic(music, current);
  }

  bool isPlayingMusic(Music music) {
    return isplay.value && isCurrentMusic(music);
  }

  playOrPauseMusic(Music music, {List<Music>? list, int? startIndex}) async {
    if (isPlayingMusic(music)) {
      onPause();
      return;
    }
    if (list != null && list.isNotEmpty) {
      playMusicList(list, startIndex: startIndex ?? list.indexOf(music));
      return;
    }
    if (isCurrentMusic(music)) {
      playLocal();
      return;
    }
    final matchedIndex = musiclist.indexWhere(
      (item) => item is Music && _isSameMusic(music, item),
    );
    if (matchedIndex >= 0) {
      playAt(musiclist[matchedIndex] as Music);
      return;
    }
    musiclist.add(music);
    player.stop();
    position.value = musiclist.length - 1;
    isplay.value = false;
    update();
    playLocal();
  }

  changePlayMode(PlayMode mode) {
    playMode.value = mode;
    update();
  }

  int _nextIndex() {
    if (musiclist.isEmpty) return 0;
    if (playMode.value == PlayMode.single) return position.value;
    if (playMode.value == PlayMode.random && musiclist.length > 1) {
      _randomSeed = (_randomSeed * 1103515245 + 12345) & 0x7fffffff;
      final next = _randomSeed % musiclist.length;
      return next == position.value ? (next + 1) % musiclist.length : next;
    }
    return (position.value + 1) % musiclist.length;
  }

  int _previousIndex() {
    if (musiclist.isEmpty) return 0;
    if (playMode.value == PlayMode.single) return position.value;
    if (playMode.value == PlayMode.random && musiclist.length > 1) {
      _randomSeed = (_randomSeed * 1103515245 + 12345) & 0x7fffffff;
      final next = _randomSeed % musiclist.length;
      return next == position.value ? (next - 1 + musiclist.length) % musiclist.length : next;
    }
    return (position.value - 1 + musiclist.length) % musiclist.length;
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
      final item = musiclist[i];
      if (item is Music && _isSameMusic(item, music)){
        if (position.value == i){
          if (isplay.isFalse) {
            playLocal();
          }
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
      position.value = _previousIndex();
      player.stop();
      onPause();
      playLocal();
    }
  }

  skipNext() async{
    if (musiclist.isNotEmpty) {
      position.value = _nextIndex();
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
      if (isplay.isFalse && (musiclist.length > 1 || playMode.value == PlayMode.single)) {
        isplay.value = true;
        position.value = _nextIndex();
        await playCachedAudio(musiclist[position.value].url);

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
}
