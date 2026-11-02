import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/repository/SqlLiteConn/music_conn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/feature/theme/type_value.dart';
import 'package:rctool/views/music_player.dart';
import 'package:rctool/widget/app_scaffold.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPage();
}

class _MusicPage extends State<MusicPage> {
  final MusicController musicController = Get.find<MusicController>();
  bool? isPlayNow;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    await _readData();
    await _loadMusicList();
  }

  Future<void> _readData() async {
    final prefs = await SharedPreferences.getInstance();
    isPlayNow = prefs.getBool(playKey);
  }

  Future<void> _loadMusicList() async {
    // 等上次会话恢复完再判断队列是否为空，避免刚启动时用曲库把恢复的队列顶掉
    await musicController.ready;
    // 队列已存在时不再用曲库覆盖：否则用户排好的顺序、增删都会在进入页面时丢失
    if (musicController.musiclist.isEmpty) {
      musicController.musiclist.value = await MusicConn.queryAll();
    }
    if (musicController.isplay.isTrue) {
      // 正在播放就保持现状，避免重进页面把当前歌曲从头再播一遍
    } else if (isPlayNow == true) {
      musicController.playAway();
    } else {
      musicController.onPause();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: const MusicPlayer(),
    );
  }
}
