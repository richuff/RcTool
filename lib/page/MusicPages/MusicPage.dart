import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:rctool/utils/SqlLiteConn/index.dart';
import 'package:rctool/widget/SearchWidget.dart';
import '../../controller/MusicController.dart';
import '../../views/MusicPlayer.dart';
import '../../widget/BackGround/MusicBackGround.dart';
import '../../widget/MainDrawer.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPage();
}

class _MusicPage extends State<MusicPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  MusicController musicController = Get.put(MusicController(),permanent: true);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_){
      _loadMusicList();
    });
  }

  Future<void> _loadMusicList() async {
    musicController.musiclist.value = await SqlLiteConn.query();
    musicController.playAway();
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
                child: IconButton(
                  hoverColor: Colors.pink[100],
                  focusColor: Colors.pink[100],
                  highlightColor: Colors.pink[200],
                  alignment: Alignment.bottomCenter,
                  icon: const Icon(
                    Icons.list,
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
          actions: [
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
