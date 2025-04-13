import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:rctool/utils/SqlLiteConn/index.dart';
import 'package:rctool/widget/SearchWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/MusicController.dart';
import '../../feature/design/IconButtonNoRipple.dart';
import '../../views/MusicPlayer.dart';
import '../../widget/BackGround/MusicBackGround.dart';
import '../../widget/MainDrawer.dart';
import 'package:rctool/feature/Theme/TypeValue.dart';

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
    musicController.musiclist.value = await SqlLiteConn.query();
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
          decoration: musicBackGround(),
          child: const Column(
            children: [MusicPlayer()],
          )),
    );
  }
}
