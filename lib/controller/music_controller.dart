import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:rctool/repository/entity/music_old.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../feature/theme/type_value.dart';
import '../repository/SqlLiteConn/play_history_conn.dart';
import '../repository/entity/Music.dart';
import '../utils/notification_helper.dart';
import 'offline_controller.dart';

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
  var volume = 1.0.obs;
  var sleepRemainingSeconds = 0.obs;
  final player = AudioPlayer();
  Duration? totalDuration;

  /// 正在为播放做缓存准备（首次播放需要下载）的歌曲，空字符串表示没有在准备。
  /// 队列页/播放条据此显示「缓存中」，避免用户以为播放器卡死。
  var loadingUrl = ''.obs;

  bool get isBuffering => loadingUrl.value.isNotEmpty;

  final cacheManager = DefaultCacheManager();
  final NotificationHelper notificationHelper = NotificationHelper();
  int _randomSeed = DateTime.now().millisecondsSinceEpoch;
  bool _cacheFirst = true;
  bool _musicNotification = true;
  Timer? _sleepTimer;

  // ── 断点续播 ──────────────────────────────────────────────
  /// 上次退出时的播放进度（只在启动恢复后、真正开始播这首歌前有效）
  Duration _resumePosition = Duration.zero;
  String _resumeUrl = '';
  int _lastPositionMs = 0;
  DateTime _lastSessionSave = DateTime.fromMillisecondsSinceEpoch(0);

  /// 迷你播放条据此显示「继续播放 xx:xx」
  Duration get resumePosition => _resumePosition;
  bool get hasResumePoint => _resumePosition.inMilliseconds > 0;

  bool get sleepTimerActive => sleepRemainingSeconds.value > 0;

  /// 设置与上次会话读取完成（曲库页等需要等它再决定是否覆盖队列）
  final Completer<void> _ready = Completer<void>();
  Future<void> get ready => _ready.future;

  String get sleepRemainingLabel {
    final seconds = sleepRemainingSeconds.value;
    final minutes = seconds ~/ 60;
    final remain = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remain.toString().padLeft(2, '0')}';
  }

  @override
  void onInit() {
    super.onInit();
    // 通知栏按钮（上一首 / 暂停 / 下一首）回调
    notificationHelper.onAction = _handleNotificationAction;
    _loadPlaybackSettings();
  }

  void _handleNotificationAction(String actionId) {
    switch (actionId) {
      case NotificationHelper.actionPrevious:
        skipPrevious();
        break;
      case NotificationHelper.actionToggle:
        isplay.value ? onPause() : playLocal();
        break;
      case NotificationHelper.actionNext:
        skipNext();
        break;
    }
  }

  /// 同步常驻播放通知（当前歌曲 + 播放状态）
  Future<void> _notifyPlayback() async {
    final music = currentMusic;
    if (!_musicNotification || music == null) {
      await notificationHelper.cancelPlaybackNotification();
      return;
    }
    await notificationHelper.showPlaybackNotification(
      title: music.songName,
      body: music.decoration.isEmpty ? '正在播放'.tr : music.decoration,
      isPlaying: isplay.value,
    );
  }

  Future<void> _loadPlaybackSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(playModeKey);
    playMode.value = PlayMode.values.firstWhere(
      (mode) => mode.name == savedMode,
      orElse: () => PlayMode.loop,
    );
    volume.value =
        (prefs.getDouble(volumeKey) ?? 1.0).clamp(0.0, 1.0).toDouble();
    _cacheFirst = prefs.getBool(cacheFirstKey) ?? true;
    _musicNotification = prefs.getBool(notificationKey) ?? true;
    try {
      await player.setVolume(volume.value);
      await _restoreSession();
      update();
    } finally {
      // 任何异常都不能让曲库页一直 await 下去
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  Future<void> updateCacheSetting(bool value) async {
    _cacheFirst = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(cacheFirstKey, value);
  }

  Future<void> updateNotificationSetting(bool value) async {
    _musicNotification = value;
    if (!value) {
      await notificationHelper.cancelAll();
    } else {
      await _notifyPlayback();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationKey, value);
  }

  Future<void> changeVolume(double value) async {
    volume.value = value.clamp(0.0, 1.0).toDouble();
    await player.setVolume(volume.value);
    update();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(volumeKey, volume.value);
  }

  void startSleepTimer(Duration duration) {
    cancelSleepTimer();
    if (duration.inSeconds <= 0) return;

    sleepRemainingSeconds.value = duration.inSeconds;
    update();
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = sleepRemainingSeconds.value - 1;
      if (remaining <= 0) {
        timer.cancel();
        _sleepTimer = null;
        sleepRemainingSeconds.value = 0;
        onPause();
        Get.snackbar(
          '睡眠定时'.tr,
          '时间到了，已自动暂停播放'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      sleepRemainingSeconds.value = remaining;
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepRemainingSeconds.value = 0;
    update();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    player.dispose();
    super.dispose();
  }

  @override
  void onReady() {
    player.onPlayerComplete.listen((event) async {
      isplay.value = false;
      update();

      playNextLocal();
    });
    // 记录进度，播放中每 4 秒落一次盘，退出/暂停时立即落盘
    player.onPositionChanged.listen((value) {
      _lastPositionMs = value.inMilliseconds;
      if (!isplay.value) return;
      if (DateTime.now().difference(_lastSessionSave).inSeconds < 4) return;
      _saveSession();
    });
  }

  /// 把队列、当前索引与进度写入本地，下次启动可原样恢复
  Future<void> _saveSession() async {
    _lastSessionSave = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    if (musiclist.isEmpty) {
      await prefs.remove(sessionQueueKey);
      await prefs.remove(sessionIndexKey);
      await prefs.remove(sessionPositionKey);
      return;
    }
    final songs =
        musiclist.whereType<Music>().map((music) => music.toJson()).toList();
    await prefs.setString(sessionQueueKey, jsonEncode(songs));
    await prefs.setInt(sessionIndexKey, position.value);
    await prefs.setInt(sessionPositionKey, _lastPositionMs);
  }

  /// 启动时恢复上次的队列与进度：只恢复到「待播放」状态，不自动出声
  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(sessionQueueKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final list = decoded.map(Music.fromJson).whereType<Music>().toList();
      if (list.isEmpty) return;
      final index = (prefs.getInt(sessionIndexKey) ?? 0)
          .clamp(0, list.length - 1)
          .toInt();
      final ms = prefs.getInt(sessionPositionKey) ?? 0;
      musiclist.value = list;
      position.value = index;
      isplay.value = false;
      _lastPositionMs = ms;
      if (ms > 1000) {
        _resumePosition = Duration(milliseconds: ms);
        _resumeUrl = list[index].url;
      }
    } catch (_) {
      // 数据损坏时忽略，队列保持为空即可
    }
  }

  void _setLoadingUrl(String url) {
    if (loadingUrl.value == url) return;
    loadingUrl.value = url;
    update();
  }

  Future<void> playCachedAudio(
    Music music, {
    bool recordHistory = true,
  }) async {
    await player.setVolume(volume.value);
    _lastPositionMs = 0;
    try {
      if (_cacheFirst) {
        // 已缓存时直接播放本地文件；未缓存时先显示「缓存中」再下载并写入缓存。
        final cached = await cacheManager.getFileFromCache(music.url);
        if (cached != null) {
          await player.play(UrlSource(cached.file.path));
        } else {
          _setLoadingUrl(music.url);
          final file = await cacheManager.getSingleFile(music.url);
          await player.play(UrlSource(file.path));
        }
      } else {
        // 关闭缓存优先后直接播放地址，不主动写入音乐缓存。
        await player.play(UrlSource(music.url));
      }
    } catch (error) {
      isplay.value = false;
      update();
      Get.snackbar(
        '播放失败'.tr,
        '@name 暂时无法播放，请检查网络后重试'.trParams({'name': music.songName}),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    } finally {
      _setLoadingUrl('');
    }

    // 断点续播：只有「启动恢复的那一首」才跳到上次的进度
    if (_resumePosition > Duration.zero && _resumeUrl == music.url) {
      try {
        await player.seek(_resumePosition);
        _lastPositionMs = _resumePosition.inMilliseconds;
      } catch (_) {
        // seek 失败就从头播，不影响正常播放
      }
    }
    _resumePosition = Duration.zero;
    _resumeUrl = '';
    _saveSession();
    _notifyPlayback();

    // 缓存优先模式下播完这段音频本地就有文件了，顺手更新离线角标
    if (_cacheFirst && Get.isRegistered<OfflineController>()) {
      Get.find<OfflineController>().markCached(music.url);
    }

    if (recordHistory) {
      try {
        await PlayHistoryConn.record(music);
      } catch (_) {
        // 历史记录失败不应影响正常播放。
      }
    }
  }

  inc(int? id, String url, String imageUrl, String songName,
      String decoration) async {
    Music music = Music(id, url, imageUrl, songName, decoration);
    for (Music lMusic in musiclist) {
      if (_isSameMusic(music, lMusic)) {
        playAt(lMusic);
        return;
      }
    }

    musiclist.add(music);
    update();

    player.stop();
    position.value = musiclist.length - 1;
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
      // 队列本身没有新增歌曲时，这里只可能是恢复暂停，不重复计数。
      playLocal(recordHistory: player.state != PlayerState.paused);
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
      // 暂停后继续不新增记录；首次从停止状态启动仍算一次播放。
      playLocal(recordHistory: player.state != PlayerState.paused);
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

  Future<void> changePlayMode(PlayMode mode) async {
    playMode.value = mode;
    update();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(playModeKey, mode.name);
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
      return next == position.value
          ? (next - 1 + musiclist.length) % musiclist.length
          : next;
    }
    return (position.value - 1 + musiclist.length) % musiclist.length;
  }

  /// 当前播放的歌曲（队列为空时返回 null）
  Music? get currentMusic {
    if (musiclist.isEmpty) return null;
    final index = position.value;
    if (index < 0 || index >= musiclist.length) return null;
    final item = musiclist[index];
    return item is Music ? item : null;
  }

  /// 按索引移除队列歌曲，返回被移除的对象（供「撤销」使用）。
  /// 移除当前播放项时保持播放索引不越界。
  Music? removeAt(int index) {
    if (index < 0 || index >= musiclist.length) return null;
    final item = musiclist[index];
    if (item is! Music) return null;
    final wasCurrent = index == position.value;
    musiclist.removeAt(index);
    if (musiclist.isEmpty) {
      position.value = 0;
    } else if (wasCurrent) {
      position.value = index.clamp(0, musiclist.length - 1).toInt();
    } else if (index < position.value) {
      position.value = position.value - 1;
    }
    update();
    return item;
  }

  /// 把歌曲插回队列（撤销移除）；插到当前位置之前的项不会打断播放。
  void insertAt(int index, Music music) {
    final target = index.clamp(0, musiclist.length).toInt();
    musiclist.insert(target, music);
    if (target <= position.value && musiclist.length > 1) {
      position.value = position.value + 1;
    }
    update();
  }

  /// 拖拽排序：调整队列顺序后，播放索引跟随原当前歌曲移动，不会串音。
  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= musiclist.length) return;
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    target = target.clamp(0, musiclist.length - 1).toInt();
    if (target == oldIndex) return;

    final current = currentMusic;
    final item = musiclist.removeAt(oldIndex);
    musiclist.insert(target, item);
    if (current != null) {
      final newPosition = musiclist.indexOf(current);
      if (newPosition >= 0) position.value = newPosition;
    }
    update();
  }

  dec(Music music) {
    final index = musiclist.indexOf(music);
    if (index < 0) return;
    removeAt(index);
  }

  /// 按比例跳转播放进度（0~1）
  Future<void> seekToFraction(double fraction) async {
    final total = totalDuration;
    if (total == null || total.inMilliseconds <= 0) return;
    final target = Duration(
      milliseconds: (total.inMilliseconds * fraction.clamp(0.0, 1.0)).round(),
    );
    await player.seek(target);
  }

  /// 清空播放队列：停止播放并重置进度，不影响曲库与歌单。
  Future<void> clearQueue() async {
    await player.stop();
    musiclist.clear();
    position.value = 0;
    isplay.value = false;
    totalDuration = null;
    _lastPositionMs = 0;
    _resumePosition = Duration.zero;
    _resumeUrl = '';
    update();
    _saveSession();
    notificationHelper.cancelPlaybackNotification();
  }

  onPause() {
    isplay.value = false;
    player.pause();
    update();
    _saveSession();
    _notifyPlayback();
  }

  playLocal({bool recordHistory = true}) async {
    if (musiclist.isNotEmpty) {
      final music = musiclist[position.value] as Music;
      if (isplay.isFalse) {
        isplay.value = true;
        update();
        await playCachedAudio(music, recordHistory: recordHistory);
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
    if (musiclist.isNotEmpty) {
      isplay.value = true;
      update();
      // 进入页面时恢复上次播放，不重复记录历史。
      await playCachedAudio(
        musiclist[position.value] as Music,
        recordHistory: false,
      );
      totalDuration = await player.getDuration();
      player.onDurationChanged.listen((Duration duration) {
        totalDuration = duration;
      });
    }
  }

  playAt(Music music) async {
    for (int i = 0; i < musiclist.length; i++) {
      final item = musiclist[i];
      if (item is Music && _isSameMusic(item, music)) {
        if (position.value == i) {
          if (isplay.isFalse) {
            playLocal(recordHistory: player.state != PlayerState.paused);
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

  skipPrevious() async {
    if (musiclist.isNotEmpty) {
      position.value = _previousIndex();
      player.stop();
      onPause();
      playLocal();
    }
  }

  skipNext() async {
    if (musiclist.isNotEmpty) {
      position.value = _nextIndex();
      player.stop();
      onPause();
      playLocal();
    }
  }

  changeLike(Music music) {
    for (int i = 0; i < musiclist.length; i++) {
      if (musiclist[i] == music) {
        musiclist[i].isFavorite = false;
        update();
      }
    }
  }

  //设置播放进度条
  void setPosition(double sliderValue) {
    double proportion = (sliderValue - 1) / 99;
    if (totalDuration != null) {
      Duration newPosition =
          Duration(seconds: (proportion * totalDuration!.inSeconds).round());
      player.seek(newPosition);
    }
  }

  //播放下一首
  void playNextLocal() async {
    if (musiclist.isNotEmpty) {
      if (isplay.isFalse &&
          (musiclist.length > 1 || playMode.value == PlayMode.single)) {
        isplay.value = true;
        position.value = _nextIndex();
        await playCachedAudio(musiclist[position.value] as Music);

        update();
      } else {
        onPause();
      }

      // 通知栏同步当前歌曲与播放状态
      _notifyPlayback();

      //监视播放进度s
      totalDuration = await player.getDuration();
      player.onDurationChanged.listen((Duration duration) {
        totalDuration = duration;
      });
    }
  }

  upDateFavorite(Music music) {
    for (int i = 0; i < musiclist.length; i++) {
      if (musiclist[i].url == music.url) {
        musiclist[i] = music;
        update();
        break;
      }
    }
  }

  String getPlaySongName() {
    return musiclist[position.value].songName;
  }

  @Deprecated("废弃isFavorite字段")
  incOld(String url, String imageUrl, String songName, String decoration,
      bool isFavorite) async {
    MusicOld music = MusicOld(url, imageUrl, songName, decoration, isFavorite);
    for (MusicOld lmusic in musiclist) {
      if (music == lmusic) {
        playAt(lmusic as Music);
        return;
      }
    }

    musiclist.add(music);
    update();

    player.stop();
    position.value = musiclist.length - 1;
    isplay.value = false;
    update();

    playLocal();
  }
}
