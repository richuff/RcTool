import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/repository/SqlLiteConn/music_conn.dart';
import 'package:rctool/widget/BackGround/back_ground_enum.dart';
import 'package:rctool/widget/search_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/music_controller.dart';
import '../../feature/design/icon_button_no_ripple.dart';
import '../../views/music_player.dart';
import '../../widget/main_drawer.dart';
import 'package:rctool/feature/Theme/type_value.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPage();
}

class _MusicPage extends State<MusicPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  MusicController musicController = Get.put(MusicController(),permanent: true);
  bool? isPlayNow;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_){
      _readData();
      _loadMusicList();
    });
  }

  // 读取数据
  Future<void> _readData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isPlayNow = prefs.getBool(playKey);
  }

  Future<void> _loadMusicList() async {
    musicController.musiclist.value = await MusicConn.queryAll();
    if (isPlayNow == true || musicController.isplay.isTrue){
      musicController.playAway();
    }else{
      musicController.onPause();
    }
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawerScrimColor: Colors.transparent,
      drawer: MainDrawer((){
        scaffoldKey.currentState?.closeDrawer();
      }),
      appBar: AppBar(
          backgroundColor: Colors.pink[50],
          leading: Builder(builder: (context) {
            return Column(children: [
              const Padding(padding: EdgeInsets.only(top: 8)),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: IconButtonNoRipple(
                  hoverColor: Colors.pink[100],
                  focusColor: Colors.pink[100],
                  highlightColor: Colors.pink[200],
                  alignment: Alignment.bottomCenter,
                  icon: const Icon(
                    Icons.menu,
                    size: 26,
                  ),
                  color: Colors.black,
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            ]);
          }),
          actions: const [
            SearchWidget()
          ]),
      body: Container(
          decoration: BackGroundEnum.musicBackGround.decoration,
          child: const Column(
            children: [MusicPlayer()],
          )),
    );
  }
}
