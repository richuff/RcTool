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
  final MusicController musicController =
      Get.put(MusicController(), permanent: true);
  bool? isPlayNow;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readData();
      _loadMusicList();
    });
  }

  Future<void> _readData() async {
    final prefs = await SharedPreferences.getInstance();
    isPlayNow = prefs.getBool(playKey);
  }

  Future<void> _loadMusicList() async {
    musicController.musiclist.value = await MusicConn.queryAll();
    if (isPlayNow == true || musicController.isplay.isTrue) {
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
